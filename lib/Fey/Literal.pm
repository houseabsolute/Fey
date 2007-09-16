package Fey::Literal;

use strict;
use warnings;

use Moose::Policy 'Fey::Policy';
use Moose;

no Moose;
__PACKAGE__->meta()->make_immutable();

use Fey::Literal::Function;
use Fey::Literal::Null;
use Fey::Literal::Number;
use Fey::Literal::String;
use Fey::Literal::Term;
use Scalar::Util qw( looks_like_number );


sub new_from_scalar
{
    return
        (   ! defined $_[1]
          ? Fey::Literal::Null->new()
          : looks_like_number( $_[1] )
          ? Fey::Literal::Number->new( $_[1] )
          : Fey::Literal::String->new( $_[1] )
        );
}

{
    my $dbh = Fey::FakeDBI->new();
    sub id
    {
        return $_[0]->sql($dbh);
    }
}

# This package allows us to use a DBI handle in id(). Even though we
# may not be quoting properly for a given DBMS, we will still generate
# unique ids, and that's all that matters.

package # Hide from PAUSE
    Fey::FakeDBI;


sub new { bless \$_[0], $_[0] }

sub isa
{
    return 1 if $_[1] eq 'DBI::db';
}

sub quote_identifier
{
    shift;

    # XXX - 3 but then we use [1] & [2] - wtf?
    if ( @_ == 3 )
    {
        return q{"} . $_[1] . q{"} . q{.} . q{"} . $_[2] . q{"}
    }
    else
    {
        return q{"} . $_[0] . q{"};
    }
}

sub quote
{
    my $text = $_[1];

    $text =~ s/"/""/g;
    return q{"} . $text . q{"};
}


1;

__END__

=head1 NAME

Fey::Literal - Represents a literal piece of a SQL statement

=head1 SYNOPSIS

  my $literal = Fey::Literal->new_from_scalar($string_or_number_or_undef);

=head1 DESCRIPTION

This class represents a literal piece of a SQL statement, such as a
string, number, or function.

It is the superclass for several more specific C<Fey::Literal>
subclasses, and also provides short

=head1 METHODS

This class provides the following methods:

=head2 Fey::Literal->new_from_scalar($scalar)

Given a string, number, or undef, this method returns a new object of
the appropriate subclass. This will be either a
C<Fey::Literal::String>, C<Fey::Literal::Number>, or
C<Fey::Literal::Null>.

=head2 $literal->id()

Returns a unique id for a literal object.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
