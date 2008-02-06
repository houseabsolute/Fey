package Fey::Literal::Number;

use strict;
use warnings;

use Moose::Policy 'MooseX::Policy::SemiAffordanceAccessor';
use MooseX::StrictConstructor;

extends 'Fey::Literal';

with 'Fey::Role::Comparable', 'Fey::Role::Selectable';

has 'number' =>
    ( is       => 'ro',
      isa      => 'Num',
      required => 1,
    );


sub new
{
    my $class = shift;

    return $class->SUPER::new( number => shift );
}

sub sql { $_[0]->number() }

sub sql_with_alias { goto &sql }

sub sql_or_alias { goto &sql }

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Fey::Literal::Number - Represents a literal number in a SQL statement

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

=head2 $number->sql()

=head2 $number->sql_with_alias()

=head2 $number->sql_or_alias()

Returns the appropriate SQL snippet.

=head1 ROLES

This class does the C<Fey::Role::Selectable> and
C<Fey::Role::Comparable> roles.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
