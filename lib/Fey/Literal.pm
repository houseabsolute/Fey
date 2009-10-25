package Fey::Literal;

use strict;
use warnings;

our $VERSION = '0.34';

use Fey::FakeDBI;
use Fey::Literal::Function;
use Fey::Literal::Null;
use Fey::Literal::Number;
use Fey::Literal::String;
use Fey::Literal::Term;
use Fey::Types;
use Scalar::Util qw( blessed looks_like_number );
use overload ();

# This needs to come before we load subclasses or shit blows up
# because we end up with a metaclass object that is a
# Class::MOP::Class, not Moose::Meta::Class.
use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

sub new_from_scalar
{
    shift;
    my $val = shift;

    return Fey::Literal::Null->new()
        unless defined $val;

    # Freaking Perl overloading is so broken! An overloaded reference
    # will not pass the type constraints, so we need to manually
    # convert it to a non-ref.
    if ( blessed $val && overload::Overloaded( $val ) )
    {
        # The stringification method will be derived from the
        # numification method if needed. This might produce strange
        # results in the case of something that overloads both
        # operations, like a number class that returns either 2 or
        # "two", but in that case the author of the class made our
        # life impossible anyway ;)
        $val = $val . '';
    }

    return looks_like_number($val)
           ? Fey::Literal::Number->new($val)
           : Fey::Literal::String->new($val);
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Fey::Literal - Factory for making a literal piece of a SQL statement

=head1 SYNOPSIS

  my $literal = Fey::Literal->new_from_scalar($string_or_number_or_undef);

=head1 DESCRIPTION

This class is a factory for creating a literal piece of a SQL statement, such
as a string, number, or function.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Literal->new_from_scalar($scalar)

Given a string, number, or undef, this method returns a new object of
the appropriate subclass. This will be either a
C<Fey::Literal::String>, C<Fey::Literal::Number>, or
C<Fey::Literal::Null>.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
