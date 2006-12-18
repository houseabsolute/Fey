package Q::Trait::Comparable;

use strict;
use warnings;

use Class::Trait 'base';


our @REQUIRES = qw( is_comparable );

sub is_comparable { 1 }


1;

__END__
