package Fey::Literal::Function;

use strict;
use warnings;

our $VERSION = '0.33';

use Fey::Types;
use Scalar::Util qw( blessed );

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

with 'Fey::Role::Comparable',
     'Fey::Role::Selectable',
     'Fey::Role::Orderable',
     'Fey::Role::Groupable' => { excludes => 'is_groupable' },
     'Fey::Role::IsLiteral';

with 'Fey::Role::HasAliasName' =>
    { generated_alias_prefix => 'FUNCTION' };

has 'function' =>
    ( is       => 'ro',
      isa      => 'Str',
      required => 1,
    );

has 'args' =>
    ( is         => 'ro',
      isa        => 'Fey::Types::ArrayRefOfFunctionArgs',
      default    => sub { [] },
      coerce     => 1,
    );

sub BUILDARGS
{
    my $class = shift;

    return { function => shift,
             args     => [ @_ ],
           };
}

sub sql
{
    my $sql = $_[0]->function();
    $sql .= '(';

    $sql .=
        ( join ', ',
          map { $_->sql( $_[1] ) }
          @{ $_[0]->args() }
        );
    $sql .= ')';
}

sub is_groupable { $_[0]->alias_name() ? 1 : 0 }

no Moose;
no Moose::Util::TypeConstraints;

__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Fey::Literal::Function - Represents a literal function in a SQL statement

=head1 SYNOPSIS

  my $function = Fey::Literal::Function->new( 'LENGTH', $column );

=head1 DESCRIPTION

This class represents a literal function in a SQL statement, such as
C<NOW()> or C<LENGTH(User.username)>.

=head1 INHERITANCE

This module is a subclass of C<Fey::Literal>.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Literal::Function->new( $function, @args )

This method creates a new C<Fey::Literal::Function> object.

It requires at least one argument, which is the name of the SQL
function that this literal represents. It can accept any number of
additional optional arguments. These arguments must be either scalars,
literals, or columns which belong to a table.

Any scalars passed in as arguments will be passed in turn to C<<
Fey::Literal->new_from_scalar() >>.

=head2 $function->set_alias_name($alias)

Use this to explicitly set a function's alias name for use in SQL. If
you don't set this it will be autogenerated as needed.

=head2 $function->function()

The function's name, as passed to the constructor.

=head2 $function->args()

Returns an array reference of the function's arguments, as passed to
the constructor.

=head2 $function->id()

The id for a function is uniquely identifies the function.

=head2 $function->sql()

=head2 $function->sql_with_alias()

=head2 $function->sql_or_alias()

Returns the appropriate SQL snippet.

Calling C<< $function->sql_with_alias() >> causes a unique alias for
the function to be created.

=head1 ROLES

This class does the C<Fey::Role::Selectable>, C<Fey::Role::Comparable>,
C<Fey::Role::Groupable>, C<Fey::Role::Orderable>, and
C<Fey::Role::HasAliasName> roles.

This class overrides the C<is_groupable()> and C<is_orderable()>
methods so that they only return true if the C<<
$function->sql_with_alias() >> has been called previously. This
function is called when a function is used in the C<SELECT> clause of
a query. A function must be used in a C<SELECT> in order to be used in
a C<GROUP BY> or C<ORDER BY> clause.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
