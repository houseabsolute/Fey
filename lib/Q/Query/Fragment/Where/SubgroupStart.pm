package Q::Query::Fragment::Where::SubgroupStart;

use strict;
use warnings;


my $Paren = '(';
sub new
{
    my $class = shift;

    return bless \$Paren, $class;
}

sub sql_for_where
{
    return $Paren;
}


1;

__END__
