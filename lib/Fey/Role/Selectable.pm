package Fey::Role::Selectable;

use strict;
use warnings;

use Moose::Role;


sub is_selectable { 1 }

no Moose::Role;

1;

__END__

=head1 NAME

Fey::Role::Selectable - A role for things that can go in a SELECT clause

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

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
