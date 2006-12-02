package Q::Trait::ColumnLike;

use strict;
use warnings;

use Class::Trait 'base';

use Class::Trait ( 'Q::Trait::Selectable' => { exclude => 'is_selectable' } );
use Class::Trait ( 'Q::Trait::Comparable' => { exclude => 'is_comparable' } );
use Class::Trait ( 'Q::Trait::Groupable' => { exclude => 'is_groupable' } );


our @REQUIRES
    = qw( id
          is_alias
          _containing_table_name_or_alias
          is_selectable
          is_comparable );


sub _containing_table_name_or_alias
{
    my $t = $_[0]->table();

    $t->is_alias() ? $t->alias_name() : $t->name();
}

sub is_selectable { return $_[0]->table() ? 1 : 0 }

sub is_comparable { return $_[0]->table() ? 1 : 0 }

sub is_groupable  { return $_[0]->table() ? 1 : 0 }
