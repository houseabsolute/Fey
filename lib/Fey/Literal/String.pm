package Fey::Literal::String;

use strict;
use warnings;

use base 'Fey::Literal';
__PACKAGE__->mk_ro_accessors
    ( qw( string ) );

use Class::Trait ( 'Fey::Trait::Selectable' );
use Class::Trait ( 'Fey::Trait::Comparable' );

use Fey::Validate
    qw( validate_pos
        SCALAR_TYPE
        QUERY_TYPE
      );


{
    my $spec = (SCALAR_TYPE);
    sub new
    {
        my $class    = shift;
        my ($string) = validate_pos( @_, $spec );

        return bless { string => $string }, $class;
    }
}

sub sql  { $_[1]->quote_string( $_[0]->string() ) }

sub sql_with_alias { goto &sql }

sub sql_or_alias { goto &sql }


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

=head1 TRAITS

This class does the C<Fey::Trait::Selectable> and
C<Fey::Trait::Comparable> traits.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
