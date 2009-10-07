package Fey::Role::TableLike;

use strict;
use warnings;

our $VERSION = '0.33';

use Moose::Role;

with 'Fey::Role::Joinable';

no Moose::Role;

1;

__END__

=head1 NAME

Fey::Role::TableLike - A role for things that are like a table

=head1 SYNOPSIS

  use Moose;

  with 'Fey::Role::TableLike';

=head1 DESCRIPTION

This role has no methods or attributes of its own. It does consume the
L<Fey::Role::Joinable> role.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
