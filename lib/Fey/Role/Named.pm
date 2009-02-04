package Fey::Role::Named;

use strict;
use warnings;

use Moose::Role;

requires 'name';

no Moose::Role;

1;

__END__

=head1 NAME

Fey::Role::Named - A role for things with a name

=head1 SYNOPSIS

  use Moose;

  with 'Fey::Role::Name';

=head1 DESCRIPTION

This role has no methods or attributes of its own, it simply requires
that the consuming class provide a C<name()> method.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
