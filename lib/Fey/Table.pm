package Fey::Table;

use strict;
use warnings;

use List::MoreUtils qw( any all first_index );
use Scalar::Util qw( blessed weaken );

use Fey::Exceptions qw( param_error );
use Fey::Validate
    qw( validate validate_pos
        UNDEF OBJECT
        SCALAR_TYPE BOOLEAN_TYPE
        COLUMN_TYPE COLUMN_OR_NAME_TYPE
        SCHEMA_TYPE );

use Moose::Policy 'MooseX::Policy::SemiAffordanceAccessor';
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;

with 'Fey::Role::Joinable';

has 'name' =>
    ( is       => 'ro',
      isa      => 'Str',
      required => 1,
    );

has 'is_view' =>
    ( is      => 'ro',
      isa     => 'Bool',
      default => 0,
    );

subtype 'ArrayOfNamedObjectSets'
    => as 'ArrayRef'
    => where { for my $arg ( @{ $_ } )
               {
                   return unless blessed $arg && $arg->isa('Fey::NamedObjectSet');
               }
               return 1;
             };

has '_keys' =>
    ( is         => 'rw',
      isa        => 'ArrayOfNamedObjectSets',
      default    => sub { [] },
    );

has '_columns' =>
    ( is      => 'ro',
      isa     => 'Fey::NamedObjectSet',
      default => sub { return Fey::NamedObjectSet->new() },
      handles => { columns => 'objects',
                   column  => 'object',
                 },
    );

has 'schema' =>
    ( is        => 'rw',
      isa       => 'Undef | Fey::Schema',
      weak_ref  => 1,
      writer    => '_set_schema',
      predicate => 'has_schema',
    );

use Fey::Column;
use Fey::NamedObjectSet;
use Fey::Schema;
use Fey::Table::Alias;
use Scalar::Util qw( blessed );


{
    my $spec = (COLUMN_TYPE);
    sub add_column
    {
        my $self = shift;
        my ($col) = validate_pos( @_, $spec );

        my $name = $col->name();
        param_error "The table already has a column named $name."
            if $self->column($name);

        $self->_columns()->add($col);

        $col->_set_table($self);

        return $self;
    }
}

{
    my $spec = (COLUMN_OR_NAME_TYPE);
    sub remove_column
    {
        my $self = shift;
        my ($col) = validate_pos( @_, $spec );

        $col = $self->column($col)
            unless blessed $col;

        if ( my $schema = $self->schema() )
        {
            for my $fk ( grep { $_->has_column($col) }
                         $schema->foreign_keys_for_table($self) )
            {
                $schema->remove_foreign_key($fk);
            }
        }

        my $name = $col->name();

        for my $k ( @{ $self->_keys() } )
        {
            $self->remove_candidate_key( $k->objects() )
                if $k->object($name);
        }

        $self->_columns()->delete($col);

        $col->_set_table(undef);

        return $self;
    }
}

sub candidate_keys
{
    my $self = shift;

    return map { [ $_->objects() ] } @{ $self->_keys() };
}

sub primary_key
{
    my $self = shift;

    my @keys = $self->candidate_keys();

    return  @{ $keys[0] || [] };
}

{
    my $spec = (COLUMN_OR_NAME_TYPE);
    sub add_candidate_key
    {
        my $self = shift;
        my (@cols) = validate_pos( @_, ( $spec ) x ( @_ ? @_ : 1 ) );

        for my $name ( map { blessed $_ ? $_->name() : $_ } @cols )
        {
            param_error "The column $name is not part of the " . $self->name() . ' table.'
                unless $self->column($name);
        }

        $_ = $self->column($_) for grep { ! blessed $_ } @cols;

        return if $self->has_candidate_key(@cols);

        my $keys = $self->_keys();

        my $set = Fey::NamedObjectSet->new(@cols);

        push @{ $keys }, $set;

        return;
    }
}

{
    my $spec = (COLUMN_OR_NAME_TYPE);
    sub remove_candidate_key
    {
        my $self = shift;
        my (@cols) = validate_pos( @_, ( $spec ) x ( @_ ? @_ : 1 ) );

        for my $name ( map { blessed $_ ? $_->name() : $_ } @cols )
        {
            param_error "The column $name is not part of the " . $self->name() . ' table.'
                unless $self->column($name);
        }

        $_ = $self->column($_) for grep { ! blessed $_ } @cols;

        my $keys = $self->_keys();

        my $set = Fey::NamedObjectSet->new(@cols);

        my $idx = first_index { $_->is_same_as($set) } @{ $keys };
        splice @{ $keys }, $idx, 1
            if $idx >= 0;

        return;
    }
}

{
    my $spec = (COLUMN_OR_NAME_TYPE);
    sub has_candidate_key
    {
        my $self = shift;
        my (@cols) = validate_pos( @_, ( $spec ) x ( @_ ? @_ : 1 ) );

        for my $name ( map { blessed $_ ? $_->name() : $_ } @cols )
        {
            param_error "The column $name is not part of the " . $self->name() . ' table.'
                unless $self->column($name);
        }

        $_ = $self->column($_) for grep { ! blessed $_ } @cols;

        my $set = Fey::NamedObjectSet->new(@cols);

        return 1 if
            any { $_->is_same_as($set) }
            @{ $self->_keys() };

        return 0;
    }
}

sub alias
{
    my $self = shift;

    return Fey::Table::Alias->new( table => $self, @_ );
}

sub is_alias { 0 }

sub sql
{
    return $_[1]->quote_identifier( $_[0]->name() );
}

sub sql_with_alias { goto &sql }

sub id { $_[0]->name() }

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Fey::Table - Represents a table (or view)

=head1 SYNOPSIS

  my $table = Fey::Table->new( name => 'User' );

=head1 DESCRIPTION

This class represents a table or view in a schema. From the standpoint
of SQL construction in Fey, a table and a view are basically the same
thing.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Table->new()

  my $table = Fey::Table->new( name => 'User' );

  my $table = Fey::Table->new( name    => 'ActiveUser',
                               is_view => 1,
                             );

This method constructs a new C<Fey::Table> object. It takes the
following parameters:

=over 4

=item * name - required

The name of the table.

=item * is_view - defaults to 0

A boolean indicating whether this table is a view.

=back

=head2 $table->name()

Returns the name of the table.

=head2 $table->is_view()

Returns a boolean indicating whether the object is a view.

=head2 $table->schema()

Returns the C<Fey::Schema> object that this table belongs to. This is
set when the table is added to a schema via the C<<
Fey::Schema->add_table() >> method.

=head2 $table->add_column($column)

This adds a new column to the schema. The column must be a
C<Fey::Column> object. Adding the column to the table sets the table
for the column, so that C<< $column->table() >> returns the correct
object.

If the table already has a column with the same name, an exception is
thrown.

=head2 $table->remove_column($column)

Remove the specified column from the table. If the column was part of
any foreign keys, these are remvoed from the schema. If this column is
part of any keys for the table, those keys will be removed. Removing
the column unsets the table for the column.

The table can be specified either by name or by passing in a
C<Fey::Column> object.

=head2 $table->column($name)

Given a column name, this method returns the matching column object,
if one exists.

=head2 $table->columns

=head2 $table->columns(@names)

When this method is called with no arguments, it returns all of the
columns in the table. If given a list of names, it returns only the
specified columns. If a name is given which doesn't match a column in
the table, then it is ignored.

=head2 $table->candidate_keys()

Returns all of the candidate keys for the table as a list. Each
element of the list is an array reference containing one or more
columns.

=head2 $table->has_candidate_key(@columns)

This method returns true if the table has the given key. A key is
identified as a list of names or C<Fey::Column> objects.

=head2 $table->add_candidate_key(@columns)

This method adds a new candidate key to the table. The list of columns
can contain either names or C<Fey::Column> objects.

A candidate key is one or more columns which uniquely identify a row
in that table.

If a name or column is specified which doesn't belong to the table, an
exception will be thrown.

=head2 $table->remove_candidate_key(@columns)

This method removes a candidate key for the table. The list of columns
can contain either names or C<Fey::Column> objects.

If a name or column is specified which doesn't belong to the table, an
exception will be thrown.

=head2 $table->keys()

Returns a list of all the candidate keys. Each items in the list is an
array reference containing one or more column objects.

=head2 $table->primary_key()

This is a convenience method that simply returns the first candidate
key added to the table. The key is returned as a list of column
objects.

=head2 $table->alias(%p)

This method returns a new C<Fey::Table::Alias> object based on the
table. Any parameters passed to this method will be passed through to
C<< Fey::Table::Alias->new() >>.

=head2 $table->is_alias()

Always returns false.

=head2 $table->sql()

=head2 $table->sql_with_alias()

Returns the appropriate SQL snippet for the table.

=head2 $table->id()

Returns a unique identifier for the table.

=head1 ROLES

This class does the C<Fey::Role::Joinable> role.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
