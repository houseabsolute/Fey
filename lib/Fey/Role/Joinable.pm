package Fey::Role::Joinable;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use Moose::Role;

sub is_joinable { $_[0]->schema() ? 1 : 0 }

1;

# ABSTRACT: A role for things that can be part of a JOIN BY clause

__END__

=head1 SYNOPSIS

  use Moose 2.1200;

  with 'Fey::Role::Joinable';

=head1 DESCRIPTION

Classes which do this role represent an object which can be part of a
C<FROM> clause.

=head1 METHODS

This role provides the following methods:

=head2 $object->is_joinable()

Returns true.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=cut
