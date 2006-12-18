package Q::Trait::Orderable;

use strict;
use warnings;

use Class::Trait 'base';


our @REQUIRES = qw( is_orderable );

sub is_orderable { 1 }


1;

__END__
