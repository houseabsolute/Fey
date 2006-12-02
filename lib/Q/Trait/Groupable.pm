package Q::Trait::Groupable;

use strict;
use warnings;

use Class::Trait 'base';


our @REQUIRES = qw( sql_for_group_by is_groupable );

sub is_groupable { 1 }


1;

__END__
