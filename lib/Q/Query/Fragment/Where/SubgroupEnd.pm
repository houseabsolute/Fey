package Q::Query::Fragment::Where::SubgroupEnd;

use strict;
use warnings;


sub new
{
    my $class = shift;

    return bless ')', $class;
}

sub as_sql
{
    return ${ $_[0] };
}


1;

__END__
