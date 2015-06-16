package Fey::SQL::Fragment::Where::Boolean;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use Fey::Types qw( WhereBoolean );

use Moose 2.1200;

has 'comparison' => (
    is       => 'ro',
    isa      => WhereBoolean,
    required => 1,
);

sub sql {
    return $_[0]->comparison();
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents an AND or OR in a WHERE clause

__END__

=head1 DESCRIPTION

This class represents a subselect an AND or OR in a WHERE clause.

It is intended solely for internal use in L<Fey::SQL> objects, and as
such is not intended for public use.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=cut
