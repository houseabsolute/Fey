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

    # REVIEW - this is a bit wack - maybe _where_clause() should be
    # public.
    my @where = $_[0]->[WHERE] ? $_[0]->[WHERE]->_where_clause( 'Fey::FakeDBI', 'no WHERE' ) : ();

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

    my $join = $_[0][TABLE1]->sql_with_alias( $_[1] );
    if ( $_[0]->[OUTER] )
    {
        $join .= ' ' . uc $_[0]->[OUTER] . ' OUTER';
    }
    $join .= ' JOIN ';
    $join .= $_[0][TABLE2]->sql_with_alias( $_[1] );
    $join .= ' ON ';

    my @s = @{ $_[0]->[FK]->source_columns() };
    my @t = @{ $_[0]->[FK]->target_columns() };

    for my $p ( pairwise { [ $a, $b ] } @s, @t )
    {
        $join .= $p->[0]->sql_or_alias( $_[1] );
        $join .= ' = ';
        $join .= $p->[1]->sql_or_alias( $_[1] );
    }

    if ( $_[0]->[WHERE] )
    {
        $join .= ' AND ' . $_[0]->[WHERE]->_where_clause( $_[1], 'no WHERE' );
    }

    return $join;
}

sub bind_params
{
    return unless $_[0]->[WHERE];

    return $_[0]->[WHERE]->_where_clause_bind_params();
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
