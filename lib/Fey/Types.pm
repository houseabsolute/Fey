package Fey::Types;

use strict;
use warnings;

our $VERSION = '0.34';

use base 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    qw( MooseX::Types::Moose Fey::Types::Internal )
);

1;

__END__

=head1 NAME

Fey::Types - Types for use in Fey

=head1 DESCRIPTION

This module defines a whole bunch of types used by the Fey core
classes. None of these types are documented for external use at the
present, though that could change in the future.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
