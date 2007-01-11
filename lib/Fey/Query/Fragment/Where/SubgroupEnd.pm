package Fey::Query::Fragment::Where::SubgroupEnd;

use strict;
use warnings;


my $Paren = ')';
sub new
{
    my $class = shift;

    return bless \$Paren, $class;
}

sub sql
{
    return $Paren;
}


1;

__END__
