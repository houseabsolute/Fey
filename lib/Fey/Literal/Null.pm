package Fey::Literal::Null;

use strict;
use warnings;

our $VERSION = '0.34';

use Fey::Types;

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

with 'Fey::Role::Comparable',
     'Fey::Role::Selectable',
     'Fey::Role::IsLiteral';


sub sql { 'NULL' }

sub sql_with_alias { goto &sql }

sub sql_or_alias { goto &sql }

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Fey::Literal::Null - Represents a literal NULL in a SQL statement

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

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
