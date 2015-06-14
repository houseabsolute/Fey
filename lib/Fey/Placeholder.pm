package Fey::Placeholder;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.43';

use Fey::Types;

use Moose 0.90;
use MooseX::SemiAffordanceAccessor 0.03;
use MooseX::StrictConstructor 0.07;

with 'Fey::Role::Comparable';

sub sql {
    return '?';
}

sub sql_or_alias { goto &sql; }

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a placeholder

__END__

=head1 SYNOPSIS

  my $placeholder = Fey::Placeholder->new()

=head1 DESCRIPTION

This class represents a placeholder in a SQL statement.

For now, this always means the string C<?>, but in the future it may
allow for numbered or named placeholders.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Placeholder->new()

This method creates a new C<Fey::Placeholder> object.

=head2 $placeholder->sql()

=head2 $placeholder->sql_or_alias()

Returns the appropriate SQL snippet.

=head1 ROLES

This class does the C<Fey::Role::Comparable> role.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=cut
