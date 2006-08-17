package Q::Accessor;

use strict;
use warnings;

use base 'Class::Accessor::Fast';

sub mutator_name_for { 'set_' . $_[1] }


1;

__END__

