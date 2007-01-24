package Fey::Trait::Groupable;

use strict;
use warnings;

use Class::Trait 'base';


our @REQUIRES = qw( is_groupable );

sub is_groupable { 1 }


1;

__END__

=head1 NAME

Fey::Trait::Groupable - A trait for things that can be part of a GROUP BY clause

=head1 SYNOPSIS

  use Class::Trait ( 'Fey::Trait::Groupable' );

=head1 DESCRIPTION

Classes which do this trait represent an object which can be part of a
C<GROUP BY> clause.

=head1 METHODS

This trait provides the following methods:

=head2 $object->is_groupable()

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
