package Fey::SQL::Fragment::Where::SubgroupStart;

use strict;
use warnings;
use namespace::autoclean;

use Moose 0.90;

my $Paren = '(';

sub sql {
    return $Paren;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents the start of a subgroup in a WHERE clause

__END__

=head1 DESCRIPTION

This class represents the start of a subgroup in a WHERE clause

It is intended solely for internal use in L<Fey::SQL> objects, and as
such is not intended for public use.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=cut
