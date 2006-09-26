package Q::Query::Fragment::Where;

use strict;
use warnings;


use constant LHS  => 0;
use constant COMP => 1;
use constant RHS  => 2;


sub new
{
    my $class = shift;

    return bless \@_, $class;
}

sub as_sql
{
    return $_[1]->_
}



1;

__END__
