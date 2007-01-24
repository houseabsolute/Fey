package Fey::Trait::Selectable;

use strict;
use warnings;

use Class::Trait 'base';


our @REQUIRES = qw( is_selectable );

sub is_selectable { 1 }


1;

__END__

=head1 NAME

Fey::Trait::Selectable - A trait for things that can go in a SELECT clause

=head1 SYNOPSIS

  use Class::Trait ( 'Fey::Trait::Selectable' );

=head1 DESCRIPTION

Classes which do this trait represent an object which can go in a
C<SELECT> clause.

=head1 METHODS

This trait provides the following methods:

=head2 $object->is_selectable()

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
