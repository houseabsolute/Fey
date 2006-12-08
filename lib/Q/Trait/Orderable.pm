package Q::Trait::Orderable;

use strict;
use warnings;

use Class::Trait 'base';


our @REQUIRES = qw( sql_for_order_by is_orderable );

sub is_orderable { 1 }


1;

__END__
