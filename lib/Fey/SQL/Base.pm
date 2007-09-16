package Fey::SQL::Base;

use strict;
use warnings;

use Moose::Policy 'Fey::Policy';
use Moose;

has 'dbh' =>
    ( is       => 'ro',
      isa      => 'DBI::db',
      required => 1,
    );

no Moose;
__PACKAGE__->meta()->make_immutable();


1;

__END__

=head1 NAME

Fey::SQL::Select - Base class for Fey::SQL::* classes

=head1 SYNOPSIS

  package Fey::SQL::Select;

  use base 'Fey::SQL::Base';

=head1 DESCRIPTION

This class provides a simple constructor and some attributes for all
types of queries.

=head1 METHODS

This class provides the following methods:

=head2 Fey::SQL::Base->new()

The constructor expects a single named argument, "dbh", which must be
a valid DBI handle.

=head2 $query->dbh()

Returns the DBI handle passed to the constructor.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
