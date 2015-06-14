package Fey::Literal::Number;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.42';

use Fey::Types qw( Num );

use Moose 0.90;
use MooseX::SemiAffordanceAccessor 0.03;
use MooseX::StrictConstructor 0.07;

with 'Fey::Role::Comparable', 'Fey::Role::Selectable', 'Fey::Role::IsLiteral';

has 'number' => (
    is       => 'ro',
    isa      => Num,
    required => 1,
);

sub BUILDARGS {
    my $class = shift;

    return { number => shift };
}

sub sql { $_[0]->number() }

sub sql_with_alias { goto &sql }

sub sql_or_alias { goto &sql }

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a literal number in a SQL statement

__END__

=head1 SYNOPSIS

  my $number = Fey::Literal::Number->new($number)

=head1 DESCRIPTION

This class represents a literal number in a SQL statement, either an
integer or float.

=head1 INHERITANCE

This module is a subclass of C<Fey::Literal>.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Literal::Number->new($number)

This method creates a new C<Fey::Literal::Number> object representing
the number passed to the constructor.

=head2 $number->number()

Returns the number as passed to the constructor.

=head2 $number->id()

The id for a number is always just the number itself.

=head2 $number->sql()

=head2 $number->sql_with_alias()

=head2 $number->sql_or_alias()

Returns the appropriate SQL snippet.

=head1 ROLES

This class does the C<Fey::Role::Selectable> and
C<Fey::Role::Comparable> roles.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=cut
