package Fey::Trait::Selectable;

use strict;
use warnings;

use Class::Trait 'base';


our @REQUIRES = qw( is_selectable );

sub is_selectable { 1 }


1;

__END__
