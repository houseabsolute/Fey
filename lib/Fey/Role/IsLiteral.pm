package Fey::Role::IsLiteral;

use strict;
use warnings;

our $VERSION = '0.34';

use Moose::Role;

requires 'sql';

sub id
{
    return $_[0]->sql('Fey::FakeDBI');
}

no Moose::Role;

1;

__END__

=head1 NAME

Fey::Role::IsLiteral - A role for things that are literals

=head1 SYNOPSIS

  use Moose;

  with 'Fey::Role::IsLiteral';

=head1 DESCRIPTION

This role provides an C<id()> method that simply calls C<<
$object->sql('Fey::FakeDBI') >>.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
