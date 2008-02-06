package Fey::Role::SQL::HasBindParams;

use strict;
use warnings;

use Moose::Role;

requires 'bind_params';

has 'auto_placeholders' =>
    ( is      => 'ro',
      isa     => 'Bool',
      default => 1,
    );


1;

__END__

=head1 NAME

Fey::Role::SQL::HasBindParams - A role for queries which can have bind parameters

=head1 SYNOPSIS

  use MooseX::StrictConstructor;

  with 'Fey::Role::SQL::HasBindParams';

=head1 DESCRIPTION

Classes which do this role represent a query which can have bind
parameters.

=head1 METHODS

This role provides the following methods:

=head2 $query->auto_placeholders()

This attribute determines whether values are automatically turned into
placeholders and stored as bind parameters.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
