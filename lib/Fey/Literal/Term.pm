package Fey::Literal::Term;

use strict;
use warnings;

use base 'Fey::Literal';
__PACKAGE__->mk_ro_accessors
    ( qw( term ) );

use Class::Trait ( 'Fey::Trait::Selectable' );
use Class::Trait ( 'Fey::Trait::Comparable' );
use Class::Trait ( 'Fey::Trait::Groupable' );
use Class::Trait ( 'Fey::Trait::Orderable' );

use Fey::Validate
    qw( validate_pos
        SCALAR_TYPE
      );


{
    my $spec = (SCALAR_TYPE);
    sub new
    {
        my $class  = shift;
        my ($term) = validate_pos( @_, $spec );

        return bless { term => $term }, $class;
    }
}

sub sql  { $_[0]->term() }

sub sql_with_alias { goto &sql }

sub sql_or_alias { goto &sql }


1;

__END__
=head1 NAME

Fey::Literal::Term - Represents a literal term in a SQL statement

=head1 SYNOPSIS

  my $term = Fey::Literal::Term->new($anything)

=head1 DESCRIPTION

This class represents a literal term in a SQL statement. A "term" in
this module means a literal term that will be used verbatim, without
quoting.

This allows you to create SQL for almost any expression, so that you
can something like this C<EXTRACT( DOY FROM TIMESTAMP
User.creation_date )>, which is a valid Postgres expression. This
would be created like this:

  my $term =
      Fey::Literal::Term->new
          ( 'DOY FROM TIMESTAMP '
             . $column->sql_or_alias( $query->quoter() ) );

  my $function = Fey::Literal::Function->new( 'EXTRACT', $term );

This ability to insert arbitrary strings into a SQL statement is meant
to be used as a back-door to support any sort of SQL snippet not
otherwise supported by the core Fey classes in a more direct ma

=head1 INHERITANCE

This module is a subclass of C<Fey::Literal>.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Literal::Term->new($term)

This method creates a new C<Fey::Literal::Term> object representing
the term passed to the constructor.

=head2 $term->term()

Returns the term as passed to the constructor.

=head2 $term->sql()

=head2 $term->sql_with_alias()

=head2 $term->sql_or_alias()

Returns the appropriate SQL snippet.

=head1 TRAITS

This class does the C<Fey::Trait::Selectable>,
C<Fey::Trait::Comparable>, C<Fey::Trait::Groupable>, and
C<Fey::Trait::Orderable> traits.

Of course, the contents of a given term may not really allow for any
of these things, but having this class do these traits means you can
freely use a term object in any part of a SQL snippet.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
