package Fey::Role::Orderable;

use strict;
use warnings;
use namespace::autoclean;

use Moose::Role;

sub is_orderable {1}

1;

# ABSTRACT: A role for things that can be part of a ORDER BY clause

__END__

=head1 SYNOPSIS

  use Moose;

  with 'Fey::Role::Orderable';

=head1 DESCRIPTION

Classes which do this role represent an object which can be part of a
C<ORDER BY> clause.

=head1 METHODS

This role provides the following methods:

=head2 $object->is_orderable()

Returns true.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=cut
