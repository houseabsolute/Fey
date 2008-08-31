package Fey::Schema;

use strict;
use warnings;

use Fey::Exceptions qw( param_error );
use Fey::Validate
    qw( validate validate_pos
        SCALAR_TYPE ARRAYREF_TYPE
        TABLE_TYPE TABLE_OR_NAME_TYPE
        FK_TYPE DBI_TYPE );

use Fey::NamedObjectSet;
use Fey::SQL;
use Fey::Table;
use Scalar::Util qw( blessed );

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

has 'name' =>
    ( is       => 'rw',
      isa      => 'Str',
      required => 1,
    );

has '_tables' =>
    ( is      => 'ro',
      isa     => 'Fey::NamedObjectSet',
      default => sub { return Fey::NamedObjectSet->new() },
      handles => { tables => 'objects',
                   table  => 'object',
                 },
    );


{
    my $spec = (TABLE_TYPE);
    sub add_table
    {
        my $self  = shift;
        my ($table) = validate_pos( @_, $spec );

        my $name = $table->name();
        param_error "The schema already contains a table named $name."
            if $self->table($name);

        $self->_tables->add($table);

        $table->_set_schema($self);

        return $self;
    }
}

{
    my $spec = (TABLE_OR_NAME_TYPE);
    sub remove_table
    {
        my $self = shift;
        my ($table) = validate_pos( @_, $spec );

        $table = $self->table($table)
            unless blessed $table;

        for my $fk ( $self->foreign_keys_for_table($table) )
        {
            $self->remove_foreign_key($fk);
        }

        $self->_tables()->delete($table);

        $table->_set_schema(undef);

        return $self;
    }
}

{
    my $spec = (FK_TYPE);
    sub add_foreign_key
    {
        my $self = shift;
        my ($fk) = validate_pos( @_, $spec );

        my $fk_id = $fk->id();

        my $source_table_name = $fk->source_table()->name();

        for my $col_name ( map { $_->name() } @{ $fk->source_columns() } )
        {
            $self->{fk}{$source_table_name}{$col_name}{$fk_id} = $fk;
        }

        my $target_table_name = $fk->target_table()->name();

        for my $col_name ( map { $_->name() } @{ $fk->target_columns() } )
        {
            $self->{fk}{$target_table_name}{$col_name}{$fk_id} = $fk;
        }

        return $self;
    }
}

{
    my $spec = (FK_TYPE);
    sub remove_foreign_key
    {
        my $self = shift;
        my ($fk) = validate_pos( @_, $spec );

        my $fk_id = $fk->id();

        my $source_table_name = $fk->source_table()->name();
        for my $col_name ( map { $_->name() } @{ $fk->source_columns() } )
        {
            delete $self->{fk}{$source_table_name}{$col_name}{$fk_id};
        }

        my $target_table_name = $fk->target_table()->name();
        for my $col_name ( map { $_->name() } @{ $fk->target_columns() } )
        {
            delete $self->{fk}{$target_table_name}{$col_name}{$fk_id};
        }

        return $self;
    }
}

{
    my $spec = (TABLE_OR_NAME_TYPE);
    sub foreign_keys_for_table
    {
        my $self    = shift;
        my ($table) = validate_pos( @_, $spec );

        my $name = blessed $table ? $table->name() : $table;

        my %fks =
            ( map { $_->id() => $_ }
              map { values %{ $self->{fk}{$name}{$_} } }
              keys %{ $self->{fk}{$name} || {} }
            );

        return values %fks;
    }
}

{
    my $spec = (TABLE_OR_NAME_TYPE);
    sub foreign_keys_between_tables
    {
        my $self    = shift;
        my ( $table1, $table2 ) = validate_pos( @_, $spec, $spec );

        my $name1 = blessed $table1 ? $table1->name() : $table1;
        my $name2 = blessed $table2 ? $table2->name() : $table2;

        my %fks =
            map { $_->id() => $_ }
            grep { $_->has_tables( $name1, $name2 ) }
            map { values %{ $self->{fk}{$name1}{$_} } }
            keys %{ $self->{fk}{$name1} || {} };

        return values %fks;
    }
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Fey::Schema - Represents a schema and contains tables and foreign keys

=head1 SYNOPSIS

  my $schema = Fey::Schema->new( name => 'MySchema' );

  $schema->add_table(...);

  $schema->add_foreign_key(...);

=head1 DESCRIPTION

This class represents a schema, which is a set of tables and foreign
keys.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Schema->new()

  my $schema = Fey::Schema->new( name => 'MySchema' );

  my $schema = Fey::Schema->new( name        => 'MySchema',
                                 sql_class => 'My::SQL' );

This method constructs a new C<Fey::Schema> object. It takes the
following parameters:

=over 4

=item * name - required

The name of the schema.

=item * sql_class - defaults to C<Fey::SQL>

The name of the base class for sql object. See the C<$schema->sql()>
method for details.

=back

=head2 $schema->name()

Returns the name of the schema.

=head2 $schema->add_table($table)

Adds the specified table to the schema. The table must be a
C<Fey::Table> object. Adding the table to the schema sets the schema
for the table, so that C<< $table->schema() >> returns the correct
object.

If the table is already part of the schema, an exception will be
thrown.

=head2 $schema->remove_table($table)

Remove the specified table from the schema. Removing the table also
removes any foreign keys which reference the table. Removing the table
unsets the schema for the table.

The table can be specified either by name or by passing in a
C<Fey::Table> object.

=head2 $schema->table($name)

Returns the table with the specified name. If no such table exists,
this method returns false.

=head2 $schema->tables()

=head2 $schema->tables(@names)

When this method is called with no arguments, it returns all of the
tables in the schema. If given a list of names, it returns only the
specified tables. If a name is given which doesn't match a table in
the schema, then it is ignored.

=head2 $schema->add_foreign_key($fk)

Adds the specified to the schema. The foreign key must be a C<Fey::FK>
object.

If the foreign key references tables which are not in the schema, an
exception will be thrown.

=head2 $schema->remove_foreign_key($fk)

Removes the specified foreign key from the schema. The foreign key
must be a C<Fey::FK> object.

=head2 $schema->foreign_keys_for_table($table)

Returns all the foreign keys which reference the specified table. The
table can be specified as a name or a C<Fey::Table> object.

=head2 $schema->foreign_keys_between_tables( $source_table, $target_table )

Returns all the foreign keys which reference both tables. The tables
can be specified as names or C<Fey::Table> objects.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
