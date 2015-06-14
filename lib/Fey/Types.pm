package Fey::Types;

use strict;
use warnings;

use base 'MooseX::Types::Combine';

our $VERSION = '0.41';

__PACKAGE__->provide_types_from(
    qw( MooseX::Types::Moose Fey::Types::Internal ));

1;

# ABSTRACT: Types for use in Fey

__END__

=head1 DESCRIPTION

This module defines a whole bunch of types used by the Fey core
classes. None of these types are documented for external use at the
present, though that could change in the future.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=cut
