package Q::Query::Fragment::SubSelect;

use strict;
use warnings;


use constant SELECT  => 0;
use constant COUNTER => 1;

my $Counter = 0;
sub new
{
    my $class  = shift;
    my $select = shift;

    return bless [ $select, $Counter++ ], $class;
}

sub id { $_[0][SELECT]->as_sql() }

sub as_sql
{
    my $sql = '( ' . $_[0][SELECT]->as_sql() . ' )';
    $sql .= ' AS SUBSELECT' . $_[0]->[COUNTER]
        if $_[2] eq 'from';

    return $sql;
}


1;

__END__
