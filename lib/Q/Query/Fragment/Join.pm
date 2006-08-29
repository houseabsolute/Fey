package Q::Query::Fragment::Join;

use strict;
use warnings;

use List::MoreUtils qw( pairwise );


use constant TABLE1 => 0;
use constant TABLE2 => 1;
use constant FK     => 2;
use constant OUTER  => 3;
use constant WHERE  => 4;

sub new
{
    my $class = shift;

    return bless \@_, $class;
}

sub id
{
    # This is a rather special case, and handling it separately makes
    # the rest of this method simpler.
    return $_[0]->[TABLE1]->id()
        unless $_[0]->[TABLE2];

    my ( $t1, $t2 ) =
        ( $_[0]->[OUTER] && $_[0]->[OUTER] ne 'full'
          ? @{ $_[0] }[ TABLE1, TABLE2 ]
          : ( sort { $a->name() cmp $b->name() }
              @{ $_[0] }[ TABLE1, TABLE2 ] )
        );

    return
        ( join "\0",
          $_[0]->[OUTER] || (),
          $t1->id(),
          $t2->id(),
          $_[0]->[FK]->id(),
        );
}

sub as_sql
{
    return $_[1]->_table_name_for_from( $_[0]->[TABLE1] )
        unless $_[0]->[TABLE2];

    my $join = $_[1]->_table_name_for_from( $_[0]->[TABLE1] );
    if ( $_[0]->[OUTER] )
    {
        $join .= ' ' . uc $_[0]->[OUTER] . ' OUTER';
    }
    $join .= ' JOIN ';
    $join .= $_[1]->_table_name_for_from( $_[0]->[TABLE2] );
    $join .= ' ON ';

    my @s = $_[0]->[FK]->source_columns();
    my @t = $_[0]->[FK]->target_columns();

    for my $p ( pairwise { [ $a, $b ] } @s, @t )
    {
        $join .= $_[1]->_fq_column_name( $p->[0] );
        $join .= ' = ';
        $join .= $_[1]->_fq_column_name( $p->[1] );
    }

    if ( $_[0]->[WHERE] )
    {

    }

    return $join;
}


1;

__END__
