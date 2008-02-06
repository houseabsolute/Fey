package Fey::FK;

use strict;
use warnings;

use Fey::Exceptions qw(param_error);
use Fey::Validate
    qw( validate validate_pos
        OBJECT ARRAYREF
        COLUMN_TYPE
        TABLE_OR_NAME_TYPE );

use List::MoreUtils qw( uniq all pairwise );
use Scalar::Util qw( blessed );

use Moose::Policy 'MooseX::Policy::SemiAffordanceAccessor';
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;

has 'id' =>
    ( is       => 'ro',
      lazy     => 1,
      default  => \&_make_id,
      init_arg => "\0id",
    );

subtype 'ArrayOfColumns'
    => as 'ArrayRef'
    => where { @{ $_ } >= 1 && all { $_ && $_->isa('Fey::Column') } @{$_} };

coerce 'ArrayOfColumns'
    => from 'Fey::Column'
    => via { [ $_ ] };

has 'source_columns' =>
    ( is       => 'ro',
      isa      => 'ArrayOfColumns',
      required => 1,
      coerce   => 1,
    );

has 'target_columns' =>
    ( is       => 'ro',
      isa      => 'ArrayOfColumns',
      required => 1,
      coerce   => 1,
    );

use Fey::Column;


sub BUILD
{
    my $self = shift;
    my $p    = shift;

    my @source = @{ $self->source_columns() };
    my @target = @{ $self->target_columns() };

    unless ( @source == @target )
    {
        param_error
            ( "The source and target arrays passed to add_foreign_key()"
              . " must contain the same number of columns." );
    }

    if ( grep { ! $_->table() } @source, @target )
    {
        param_error "All columns passed to add_foreign_key() must have a table.";
    }

    for my $p ( [ source => \@source ], [ target => \@target ]  )
    {
        my ( $name, $array ) = @{$p};
        if ( uniq( map { $_->table() } @{$array} ) > 1 )
        {
            param_error
                ( "Each column in the $name argument to add_foreign_key()"
                  . " must come from the same table." );
        }
    }

    return
}

sub _make_id
{
    my $self = shift;

    return join "\0",
        ( sort
          map { $_->table()->name() . q{.} . $_->name() }
          @{ $self->source_columns() }, @{ $self->target_columns() }
        );
}

sub column_pairs
{
    my $self = shift;

    my @s = @{ $self->source_columns() };
    my @t = @{ $self->target_columns() };

    return pairwise { [ $a, $b ] } @s, @t;
}

sub source_table
{
    my $self = shift;

    return $self->source_columns()->[0]->table();
}

sub target_table
{
    my $self = shift;

    return $self->target_columns()->[0]->table();
}

{
    my $spec = (TABLE_OR_NAME_TYPE);
    sub has_tables
    {
        my $self = shift;
        my ( $table1, $table2 ) = validate_pos( @_, $spec, $spec );

        my $name1 = blessed $table1 ? $table1->name() : $table1;
        my $name2 = blessed $table2 ? $table2->name() : $table2;

        my @looking_for = sort $name1, $name2;
        my @have =
            sort map { $_->name() } $self->source_table(), $self->target_table();

        return (    $looking_for[0] eq $have[0]
                 && $looking_for[1] eq $have[1] );
   }
}

{
    my $spec = (COLUMN_TYPE);
    sub has_column
    {
        my $self  = shift;
        my ($col) = validate_pos( @_, $spec );

        my $table_name = $col->table()->name();

        my @cols;
        for my $part ( qw( source target ) )
        {
            my $table_meth = $part . '_table';
            if ( $self->$table_meth()->name() eq $table_name )
            {
                my $col_meth = $part . '_columns';
                @cols = @{ $self->$col_meth() };
            }
        }

        return 0 unless @cols;

        my $col_name = $col->name();

        return 1 if grep { $_->name() eq $col_name } @cols;

        return 0;
    }
}

sub is_self_referential
{
    my $self = shift;

    return $self->source_table()->name() eq $self->target_table()->name();
}

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Fey::FK - Represents a foreign key

=head1 SYNOPSIS

  my $fk = Fey::FK->new( source => $user_id_from_user_table,
                         target => $user_id_from_department_table,
                       );

=head1 DESCRIPTION

This class represents a foreign key, connecting one or more columns in
one table to columns in another table.

=head1 METHODS

This class provides the following methods:

=head2 Fey::FK->new()

This method constructs a new C<Fey::FK> object. It takes the following
parameters:

=over 4

=item * source - required

=item * target - required

These parameters must be either a single C<Fey::Column> object or an
array reference containing one or more column objects.

The number of columns for the source and target must be the same.

=back

=head2 $fk->source_table()

=head2 $fk->target_table()

Returns the appropriate C<Fey::Table> object.

=head2 $fk->source_columns()

=head2 $fk->target_columns()

Returns the appropriate list of C<Fey::Column> objects as an array
reference.

=head2 $fk->column_pairs()

Returns a list of array references. Each reference contains two
C<Fey::Column> objects, one from the source table and one from the
target.

=head2 $fk->has_tables( $table1, $table2 )

This method returns true if the foreign key includes both of the
specified tables. The talbles can be specified by name or as
C<Fey::Table> objects.

=head2 $fk->has_column($column)

Given a C<Fey::Column> object, this method returns true if the foreign
key includes the specified column.

=head2 $fk->is_self_referential

This returns true if the the source and target tables for the foreign
key are the same table.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
