package Fey::Literal::Term;

use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

extends 'Fey::Literal';

with 'Fey::Role::Comparable', 'Fey::Role::Selectable',
     'Fey::Role::Orderable', 'Fey::Role::Groupable';

has 'term' =>
    ( is       => 'ro',
      isa      => 'Value',
      required => 1,
    );



sub BUILDARGS
{
    my $class = shift;

    return { term => shift };
}

sub sql { $_[0]->term() }

sub sql_with_alias { goto &sql }

sub sql_or_alias { goto &sql }

no Moose;

__PACKAGE__->meta()->make_immutable();

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
             . $column->sql_or_alias( $sql->dbh() ) );

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

=head1 ROLES

This class does the C<Fey::Role::Selectable>,
C<Fey::Role::Comparable>, C<Fey::Role::Groupable>, and
C<Fey::Role::Orderable> roles.

Of course, the contents of a given term may not really allow for any
of these things, but having this class do these roles means you can
freely use a term object in any part of a SQL snippet.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
