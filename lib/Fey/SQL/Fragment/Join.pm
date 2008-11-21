package Fey::SQL::Fragment::Join;

use strict;
use warnings;

use Fey::FakeDBI;
use List::MoreUtils qw( pairwise );

use constant TABLE1 => 0;
use constant TABLE2 => 1;
use constant FK     => 2;
use constant OUTER  => 3;
use constant WHERE  => 4;

sub new
{
    my $class = shift;

    # REVIEW - should we do some parameter validation here?

    my $self = bless \@_, $class;

    # Make it '' to avoid undef comparison later in id().
    $self->[OUTER] = ''
        unless $self->[OUTER];

    return $self;
}

sub id
{
    # This is a rather special case, and handling it separately makes
    # the rest of this method simpler.
    return $_[0]->[TABLE1]->id()
        unless $_[0]->[TABLE2];

    my ( $t1, $t2 ) =
        ( $_[0]->[OUTER] ne 'full'
          ? @{ $_[0] }[ TABLE1, TABLE2 ]
          : ( sort { $a->name() cmp $b->name() }
              @{ $_[0] }[ TABLE1, TABLE2 ] )
        );

    my @outer = $_[0]->[OUTER] ? $_[0]->[OUTER] : ();

    my @where = $_[0]->[WHERE] ? $_[0]->[WHERE]->where_clause( 'Fey::FakeDBI', 'no WHERE' ) : ();

    return
        ( join "\0",
          @outer,
          $t1->id(),
          $t2->id(),
          $_[0]->[FK]->id(),
          @where,
        );
}

sub sql_with_alias
{
    return $_[0][TABLE1]->sql_with_alias( $_[1] )
        unless $_[0]->[TABLE2];

    my @unseen_tables =
        grep { ! $_[2]->{ $_->id() } } @{ $_[0] }[ TABLE1, TABLE2 ];

    # This is a pathological case, since it means _both_ tables have
    # already been joined as part of the query. Why would you then
    # join them again?
    return '' unless @unseen_tables;

    if ( @unseen_tables == 1 )
    {
        return $_[0]->_join_one_table( $_[1], @unseen_tables );
    }
    else
    {
        return $_[0]->_join_both_tables( $_[1] );
    }
}

# This could produce gibberish for an OUTER JOIN, but that would mean
# that the query is fundamentally wrong anyway (since you can't OUTER
# JOIN a table you've already joined with a normal join previously).
sub _join_one_table
{
    my $join = '';

    if ( $_[0]->[OUTER] )
    {
        $join .= uc $_[0]->[OUTER] . ' OUTER';
    }

    $join .= q{ } if length $join;
    $join .= 'JOIN ';
    $join .= $_[2]->sql_with_alias( $_[1] );

    $join .= $_[0]->_on_clause( $_[1] );
    $join .= $_[0]->_where_clause( $_[1] );
    $join .= ')';

    return $join;
}

sub _join_both_tables
{
    my $join = $_[0]->[TABLE1]->sql_with_alias( $_[1] );

    if ( $_[0]->[OUTER] )
    {
        $join .= ' ' . uc $_[0]->[OUTER] . ' OUTER';
    }

    $join .= ' JOIN ';
    $join .= $_[0]->[TABLE2]->sql_with_alias( $_[1] );

    $join .= $_[0]->_on_clause( $_[1] );
    $join .= $_[0]->_where_clause( $_[1] );
    $join .= ')';

    return $join;
}

sub _on_clause
{
    my $on .= ' ON (';

    my @s = @{ $_[0]->[FK]->source_columns() };
    my @t = @{ $_[0]->[FK]->target_columns() };

    for my $p ( pairwise { [ $a, $b ] } @s, @t )
    {
        $on .= $p->[0]->sql_or_alias( $_[1] );
        $on .= ' = ';
        $on .= $p->[1]->sql_or_alias( $_[1] );
    }

    return $on;
}

sub _where_clause
{
    return '' unless $_[0]->[WHERE];

    return ' AND ' . $_[0]->[WHERE]->where_clause( $_[1], 'no WHERE' );
}

sub tables
{
    return grep { defined } @{ $_[0] }[ TABLE1, TABLE2 ];
}

sub bind_params
{
    return unless $_[0]->[WHERE];

    return $_[0]->[WHERE]->bind_params();
}

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

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
