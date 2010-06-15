package Fey::Role::Selectable;

use strict;
use warnings;
use namespace::autoclean;

use Moose::Role;

sub is_selectable {1}

1;

# ABSTRACT: A role for things that can go in a SELECT clause

__END__

=head1 SYNOPSIS

  use Moose;

  with 'Fey::Role::Selectable';

=head1 DESCRIPTION

Classes which do this role represent an object which can go in a
C<SELECT> clause.

=head1 METHODS

This role provides the following methods:

=head2 $object->is_selectable()

Returns true.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=cut
