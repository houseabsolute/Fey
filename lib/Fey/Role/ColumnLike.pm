package Fey::Role::ColumnLike;

use strict;
use warnings;

use Moose::Role;

{
    # This is a nasty hack because when M::M::R sees a conflicting
    # role (two roles sharing the same method) it simply adds that
    # role to the list of required methods for the importing class,
    # but in this case it makes no sense, since I want ColumnLike to
    # basically replace the various is_* methods from Seletable,
    # Comparable, etc.
    package Moose::Meta::Role;

    no warnings 'redefine';
sub _apply_methods {
    my ($self, $other) = @_;
    foreach my $method_name ($self->get_method_list) {
        # it if it has one already
        if ($other->has_method($method_name) &&
            # and if they are not the same thing ...
            $other->get_method($method_name)->body != $self->get_method($method_name)->body) {
            # see if we are composing into a role
            if ($other->isa('Moose::Meta::Role')) {
                # NOTE:
                # we have to remove the method from our 
                # role, if this is being called from combine()
                # which means the meta is an anon class
                # this *may* cause problems later, but it 
                # is probably fairly safe to assume that 
                # anon classes will only be used internally
                # or by people who know what they are doing
                $other->Moose::Meta::Class::remove_method($method_name)
                    if $other->name =~ /__COMPOSITE_ROLE_SANDBOX__/;
            }
            else {
                next;
            }
        }
        else {
            # add it, although it could be overriden 
            $other->alias_method(
                $method_name,
                $self->get_method($method_name)
            );
        }
    }
}
}


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
