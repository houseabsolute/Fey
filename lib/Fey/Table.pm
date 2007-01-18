package Fey::Table;

use strict;
use warnings;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_ro_accessors
    ( qw( name is_view schema ) );

use Scalar::Util qw( blessed weaken );

use Class::Trait ( 'Fey::Trait::Joinable' );

use Fey::Exceptions qw( param_error );
use Fey::Validate
    qw( validate validate_pos
        UNDEF OBJECT
        SCALAR_TYPE BOOLEAN_TYPE
        COLUMN_TYPE COLUMN_OR_NAME_TYPE
        SCHEMA_TYPE );

use Fey::Column;
use Fey::Table::Alias;
use Scalar::Util qw( blessed );


{
    my $spec = { name    => SCALAR_TYPE,
                 is_view => BOOLEAN_TYPE( default => 0 ),
               };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $self =
            bless { %p,
                    columns => {},
                  }, $class;

        return $self;
    }
}

{
    my @spec = (COLUMN_TYPE);
    sub add_column
    {
        my $self = shift;
        my ($col) = validate_pos( @_, @spec );

        my $name = $col->name();
        param_error "The table already has a column named $name."
            if $self->column($name);

        $self->{columns}{$name} = $col;

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

        $self->set_primary_key
            ( grep { $_->name() ne $name } $self->primary_key() );

        delete $self->{columns}{$name};
        $col->_set_table(undef);

        return $self;
    }
}

{
    my $spec = (SCALAR_TYPE);
    sub column
    {
        my $self = shift;
        my ($name) = validate_pos( @_, $spec );

        return unless $self->{columns}{$name};
        return $self->{columns}{$name};
    }
}

sub columns
{
    my $self = shift;

    return values %{ $self->{columns} } unless @_;

    return map { $self->{columns}{$_} || () } @_;
}

{
    my $spec = (COLUMN_OR_NAME_TYPE);
    sub set_primary_key
    {
        my $self = shift;
        my @names =
            ( map { ref $_ ? $_->name() : $_ }
              validate_pos( @_, ($spec) x @_ )
            );

        for my $name (@names)
        {
            param_error "The column $name is not part of the " . $self->name() . ' table.'
                unless $self->column($name);
        }

        $self->{pk} = [ map { $self->column($_) } @names ];

        return $self;
    }
}

sub primary_key { @{ $_[0]->{pk} || [] } }

{
    # This method is private but intended to be called by Fey::Schema,
    # but not by anything else.
    my $spec = ( { type => UNDEF | OBJECT,
                   callbacks =>
                   { 'undef or schema' =>
                     sub { ! defined $_[0]
                           || $_[0]->isa('Fey::Schema') },
                   },
                 } );
    sub _set_schema
    {
        my $self     = shift;
        my ($schema) = validate_pos( @_, $spec );

        $self->{schema} = $schema;
        weaken $self->{schema}
            if $self->{schema};

        return $self
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
any foreign keys, these are remvoed from the schema. It will also be
removed from the table's primary key if necessary. Removing the column
unsets the table for the column.

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

=head2 $table->set_primary_key(@columns)

This method sets the columns primary key. The list of columns can
contain either names or C<Fey::Column> objects.

If a name or column is specified which doesn't belong to the table, an
exception will be thrown.

=head2 $table->primary_key()

Returns the list of columns which make up the table's primary key.

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

=head1 TRAITS

This class does the C<Fey::Trait::Joinable> trait.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
