package Q::Placeholder;

use strict;
use warnings;

use Class::Trait ( 'Q::Trait::Comparable' );


sub new
{
    my $str = '?';
    return bless \$str, $_[0];
}

sub sql { '?' }

sub sql_or_alias { goto &sql }


1;

__END__

