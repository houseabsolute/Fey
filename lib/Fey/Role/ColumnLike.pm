package Fey::Role::ColumnLike;

use strict;
use warnings;

use Fey::Role;
use Moose::Role;

with 'Fey::Role::Selectable', 'Fey::Role::Comparable',
     'Fey::Role::Groupable', 'Fey::Role::Orderable';

requires 'id', 'is_alias';


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

Fey::Role::ColumnLike - A role for "column-like" behavior

=head1 SYNOPSIS

  use Moose;

  with 'Fey::Role::ColumnLike';

=head1 DESCRIPTION

Class which do this role are "column-like" . This role aggregates
several other roles for the L<Fey::Column> and L<Fey::Column::Alias>
classes.

=head1 METHODS

This role provides the following methods:

=head2 $column->is_selectable()

=head2 $column->is_comparable()

=head2 $column->is_groupable()

=head2 $column->is_orderable()

These methods all return true when the C<< $column->table() >>
returns an object.

=head1 ROLES

This class does the C<Fey::Role::Selectable>,
C<Fey::Role::Comparable>, C<Fey::Role::Groupable>, and
C<Fey::Role::Orderable> roles.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
