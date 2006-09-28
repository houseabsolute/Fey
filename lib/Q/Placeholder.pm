package Q::Placeholder;

use strict;
use warnings;


sub new
{
    my $str = '?';
    return bless \$str, $_[0];
}


1;

__END__

