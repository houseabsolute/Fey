package Q::Trait::Selectable;

use strict;
use warnings;

use Class::Trait 'base';


our @REQUIRES = qw( sql_for_select is_selectable );

sub is_selectable { 1 }


1;

__END__
