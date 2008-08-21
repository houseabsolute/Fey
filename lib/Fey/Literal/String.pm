package Fey::Literal::String;

use strict;
use warnings;

use Moose::Policy 'MooseX::Policy::SemiAffordanceAccessor';
use MooseX::StrictConstructor;

extends 'Fey::Literal';

with 'Fey::Role::Comparable', 'Fey::Role::Selectable';

has 'string' =>
    ( is       => 'ro',
      isa      => 'Str',
      required => 1,
    );


sub BUILDARGS
{
    my $class = shift;

    return { string => shift };
}

sub sql { $_[1]->quote( $_[0]->string() ) }

sub sql_with_alias { goto &sql }

sub sql_or_alias { goto &sql }

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Fey::Literal::String - Represents a literal string in a SQL statement

=head1 SYNOPSIS

  my $string = Fey::Literal::String->new($string)

=head1 DESCRIPTION

This class represents a literal string in a SQL statement.

=head1 INHERITANCE

This module is a subclass of C<Fey::Literal>.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Literal::String->new($string)

This method creates a new C<Fey::Literal::String> object representing
the string passed to the constructor.

=head2 $string->string()

Returns the string as passed to the constructor.

=head2 $string->sql()

=head2 $string->sql_with_alias()

=head2 $string->sql_or_alias()

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
