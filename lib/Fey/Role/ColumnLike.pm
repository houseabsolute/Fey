package Fey::Role::ColumnLike;

use strict;
use warnings;

use Moose::Role;

# This seems weird, but basically we're saying that column-like things
# do these four roles, but the implementation is different for
# column-like things (than for example, selectable things).
with ( 'Fey::Role::Selectable' => { excludes => 'is_selectable' },
       'Fey::Role::Comparable' => { excludes => 'is_comparable' },
       'Fey::Role::Groupable'  => { excludes => 'is_groupable' },
       'Fey::Role::Orderable'  => { excludes => 'is_orderable' },
     );

requires '_build_id', 'is_alias';


sub _containing_table_name_or_alias
{
    my $t = $_[0]->table();

    $t->is_alias() ? $t->alias_name() : $t->name();
}

sub is_selectable { return $_[0]->table() ? 1 : 0 }

sub is_comparable { return $_[0]->table() ? 1 : 0 }

sub is_groupable  { return $_[0]->table() ? 1 : 0 }

sub is_orderable  { return $_[0]->table() ? 1 : 0 }

no Moose::Role;

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

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
