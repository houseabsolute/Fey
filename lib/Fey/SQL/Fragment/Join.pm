package Fey::SQL::Fragment::Join;

use strict;
use warnings;

use Fey::FakeDBI;
use Fey::Types;
use List::AllUtils qw( pairwise );

use Moose;

has '_table1' =>
    ( is       => 'ro',
      does     => 'Fey::Role::TableLike',
      required => 1,
      init_arg => 'table1',
    );

has '_table2' =>
    ( is        => 'ro',
      does      => 'Fey::Role::TableLike',
      predicate => '_has_table2',
      init_arg  => 'table2',
    );

has '_fk' =>
    ( is       => 'ro',
      isa      => 'Fey::FK',
      init_arg => 'fk',
    );

has '_outer_type' =>
    ( is        => 'ro',
      isa       => 'Fey.Type.OuterJoinType',
      predicate => '_has_outer_type',
      init_arg  => 'outer_type',
    );

has '_where' =>
    ( is        => 'ro',
      isa       => 'Fey::SQL::Where',
      predicate => '_has_where',
      init_arg  => 'where',
    );


sub id
{
    my $self = shift;

    # This is a rather special case, and handling it separately makes
    # the rest of this method simpler.
    return $self->_table1()->id()
        unless $self->_has_table2();

    my @tables = $self->tables();
    @tables = sort { $a->name() cmp $b->name() } @tables
        unless $self->_is_left_or_right_outer_join();

    my @outer;
    @outer = $self->_outer_type() if $self->_has_outer_type();

    my @where;
    @where = $self->_where()->where_clause( 'Fey::FakeDBI', 'no WHERE' )
        if $self->_has_where();

    return
        ( join "\0",
          @outer,
          ( map { $_->id() } @tables ),
          $self->_fk()->id(),
          @where,
        );
}

sub _is_left_or_right_outer_join
{
    my $self = shift;

    return $self->_has_outer_type() && $self->_outer_type() =~ /^(?:right|left)$/;
}

sub tables
{
    my $self = shift;

    return grep { defined } ( $self->_table1(), $self->_table2() );
}

sub sql_with_alias
{
    my $self       = shift;
    my $dbh        = shift;
    my $joined_ids = shift;

    return $self->_table1()->sql_with_alias( $dbh )
        unless $self->_has_table2();

    my @unseen_tables =
        grep { ! $joined_ids->{ $_->id() } } $self->tables();

    # This is a pathological case, since it means _both_ tables have
    # already been joined as part of the query. Why would you then
    # join them again?
    return '' unless @unseen_tables;

    if ( @unseen_tables == 1 )
    {
        return $self->_join_one_table( $dbh, @unseen_tables );
    }
    else
    {
        return $self->_join_both_tables( $dbh );
    }
}

# This could produce gibberish for an OUTER JOIN, but that would mean
# that the query is fundamentally wrong anyway (since you can't OUTER
# JOIN a table you've already joined with a normal join previously).
sub _join_one_table
{
    my $self         = shift;
    my $dbh          = shift;
    my $unseen_table = shift;

    my $join = '';

    $join .= uc $self->_outer_type() . ' OUTER'
        if $self->_has_outer_type();

    $join .= q{ } if length $join;
    $join .= 'JOIN ';
    $join .= $unseen_table->sql_with_alias( $dbh );

    $join .= $self->_on_clause( $dbh );
    $join .= $self->_where_clause( $dbh );
    $join .= ')';

    return $join;
}

sub _join_both_tables
{
    my $self = shift;
    my $dbh  = shift;

    my $join = $self->_table1()->sql_with_alias( $dbh );

    $join .= q{ } . uc $self->_outer_type() . ' OUTER'
        if $self->_has_outer_type();

    $join .= ' JOIN ';
    $join .= $self->_table2()->sql_with_alias( $dbh );

    $join .= $self->_on_clause( $dbh );
    $join .= $self->_where_clause( $dbh );
    $join .= ')';

    return $join;
}

sub _on_clause
{
    my $self = shift;
    my $dbh  = shift;

    my $on .= ' ON (';

    my @s = @{ $self->_fk()->source_columns() };
    my @t = @{ $self->_fk()->target_columns() };

    for my $p ( pairwise { [ $a, $b ] } @s, @t )
    {
        $on .= $p->[0]->sql_or_alias( $dbh );
        $on .= ' = ';
        $on .= $p->[1]->sql_or_alias( $dbh );
    }

    return $on;
}

sub _where_clause
{
    my $self = shift;
    my $dbh  = shift;

    return '' unless $self->_has_where();

    return ' AND ' . $self->_where()->where_clause( $dbh, 'no WHERE' );
}

sub bind_params
{
    my $self = shift;

    return unless $self->_has_where();

    return $self->_where()->bind_params();
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Fey::SQL::Fragment::Join - Represents a single join in a FROM clause

=head1 DESCRIPTION

This class represents part of a C<FROM> clause, usually a join, but it
can also represent a single table or subselect.

It is intended solely for internal use in L<Fey::SQL> objects, and as
such is not intended for public use.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
