package Fey::SQL::Fragment::Where::SubgroupStart;

use strict;
use warnings;

our $VERSION = '0.34';

use Moose;

my $Paren = '(';

sub sql
{
    return $Paren;
}

no Moose;

__PACKAGE__->meta()->make_immutable();


1;

__END__

=head1 NAME

Fey::SQL::Fragment::Where::Boolean - Represents the start of a subgroup in a WHERE clause

=head1 DESCRIPTION

This class represents the start of a subgroup in a WHERE clause

It is intended solely for internal use in L<Fey::SQL> objects, and as
such is not intended for public use.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
