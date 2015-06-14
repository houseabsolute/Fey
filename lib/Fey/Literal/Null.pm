package Fey::Literal::Null;

use strict;
use warnings;
use namespace::autoclean;

use Fey::Types;

use Moose 0.90;
use MooseX::SemiAffordanceAccessor 0.03;
use MooseX::StrictConstructor 0.07;

with 'Fey::Role::Comparable', 'Fey::Role::Selectable', 'Fey::Role::IsLiteral';

sub sql {'NULL'}

sub sql_with_alias { goto &sql }

sub sql_or_alias { goto &sql }

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a literal NULL in a SQL statement

__END__

=head1 SYNOPSIS

  my $null = Fey::Literal::Null->new()

=head1 DESCRIPTION

This class represents a literal C<NULL> in a SQL statement.

=head1 INHERITANCE

This module is a subclass of C<Fey::Literal>.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Literal::Null->new()

This method creates a new C<Fey::Literal::Null> object.

=head2 $null->id()

The id for a null is always just "NULL".

=head2 $null->sql()

=head2 $null->sql_with_alias()

=head2 $null->sql_or_alias()

Returns the appropriate SQL snippet.

=head1 ROLES

This class does the C<Fey::Role::Selectable> and
C<Fey::Role::Comparable> roles.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=cut
