package Fey::Role::Joinable;

use strict;
use warnings;

use Moose::Role;


sub is_joinable { $_[0]->schema() ? 1 : 0 }

no Moose::Role;

1;

__END__

=head1 NAME

Fey::Role::Joinable - A role for things that can be part of a JOIN BY clause

=head1 SYNOPSIS

  use MooseX::StrictConstructor;

  with 'Fey::Role::Joinable';

=head1 DESCRIPTION

Classes which do this role represent an object which can be part of a
C<FROM> clause.

=head1 METHODS

This role provides the following methods:

=head2 $object->is_joinable()

Returns true.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
