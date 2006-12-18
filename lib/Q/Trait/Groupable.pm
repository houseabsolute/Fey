package Q::Trait::Groupable;

use strict;
use warnings;

use Class::Trait 'base';


our @REQUIRES = qw( is_groupable );

sub is_groupable { 1 }


1;

__END__
