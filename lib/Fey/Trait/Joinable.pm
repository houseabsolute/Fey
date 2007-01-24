package Fey::Trait::Joinable;

use strict;
use warnings;

use Class::Trait 'base';


our @REQUIRES = qw( is_joinable );

sub is_joinable { $_[0]->schema() ? 1 : 0 }


1;

__END__

=head1 NAME

Fey::Trait::Joinable - A trait for things that can be part of a JOIN BY clause

=head1 SYNOPSIS

  use Class::Trait ( 'Fey::Trait::Joinable' );

=head1 DESCRIPTION

Classes which do this trait represent an object which can be part of a
C<FROM> clause.

=head1 METHODS

This trait provides the following methods:

=head2 $object->is_joinable()

Returns true.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
