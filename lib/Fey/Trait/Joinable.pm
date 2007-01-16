package Fey::Trait::Joinable;

use strict;
use warnings;

use Class::Trait 'base';


our @REQUIRES = qw( is_joinable );

sub is_joinable { $_[0]->schema() ? 1 : 0 }


1;

__END__
