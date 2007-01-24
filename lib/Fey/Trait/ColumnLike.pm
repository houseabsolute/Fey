package Fey::Trait::ColumnLike;

use strict;
use warnings;

use Class::Trait 'base';

use Class::Trait ( 'Fey::Trait::Selectable' => { exclude => 'is_selectable' },
                   'Fey::Trait::Comparable' => { exclude => 'is_comparable' },
                   'Fey::Trait::Groupable' => { exclude => 'is_groupable' },
                   'Fey::Trait::Orderable' => { exclude => 'is_orderable' },
                 );


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

sub is_orderable  { return $_[0]->table() ? 1 : 0 }

1;

__END__

=head1 NAME

Fey::Trait::ColumnLike - A trait for "column-like" behavior

=head1 SYNOPSIS

  use Class::Trait ( 'Fey::Trait::ColumnLike' );

=head1 DESCRIPTION

Class which do this trait are "column-like" . This trait aggregates
several other traits for the L<Fey::Column> and L<Fey::Column::Alias>
classes.

=head1 METHODS

This trait provides the following methods:

=head2 $column->is_selectable()

=head2 $column->is_comparable()

=head2 $column->is_groupable()

=head2 $column->is_orderable()

These methods all return true when the C<< $column->table() >>
returns an object.

=head1 TRAITS

This class does the C<Fey::Trait::Selectable>,
C<Fey::Trait::Comparable>, C<Fey::Trait::Groupable>, and
C<Fey::Trait::Orderable> traits.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
