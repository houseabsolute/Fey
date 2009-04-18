package Fey::Role::SQL::HasBindParams;

use strict;
use warnings;

use Moose::Role;

has '_bind_params' =>
    ( metaclass => 'Collection::Array',
      is        => 'ro',
      isa       => 'ArrayRef',
      default   => sub { [] },
      provides  => { push => '_add_bind_param',
                   },
      init_arg  => undef,
    );

has 'auto_placeholders' =>
    ( is      => 'ro',
      isa     => 'Bool',
      default => 1,
    );

# This needs to be a method and not a provides accessor so it can be
# excluded by classes which need to exclude it.
sub bind_params
{
    return @{ $_[0]->_bind_params() };
}

no Moose::Role;

1;

__END__

=head1 NAME

Fey::Role::SQL::HasBindParams - A role for queries which can have bind parameters

=head1 SYNOPSIS

  use Moose;

  with 'Fey::Role::SQL::HasBindParams';

=head1 DESCRIPTION

Classes which do this role represent a query which can have bind
parameters.

=head1 METHODS

This role provides the following methods:

=head2 $query->bind_params()

Returns the bind params associated with the query.

=head2 $query->auto_placeholders()

This attribute determines whether values are automatically turned into
placeholders and stored as bind parameters.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
