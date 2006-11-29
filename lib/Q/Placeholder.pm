package Q::Placeholder;

use strict;
use warnings;

use Class::Trait ( 'Q::Trait::Comparable' );


sub new
{
    my $str = '?';
    return bless \$str, $_[0];
}

sub sql_for_compare { ${ $_[0] } }


1;

__END__

