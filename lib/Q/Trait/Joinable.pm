package Q::Trait::Joinable;

use strict;
use warnings;

use Class::Trait 'base';


our @REQUIRES = qw( is_joinable );

sub is_joinable { 1 }


1;

__END__

