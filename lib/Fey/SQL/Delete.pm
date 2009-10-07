package Fey::SQL::Delete;

use strict;
use warnings;

our $VERSION = '0.33';

use Fey::Types;
use Scalar::Util qw( blessed );

use Moose;
use MooseX::Params::Validate qw( pos_validated_list );
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

with 'Fey::Role::SQL::HasWhereClause',
     'Fey::Role::SQL::HasOrderByClause',
     'Fey::Role::SQL::HasLimitClause';

with 'Fey::Role::SQL::HasBindParams' => { excludes => 'bind_params' };

has '_from' =>
    ( is       => 'rw',
      isa      => 'ArrayRef',
      default  => sub { [] },
      init_arg => undef,
    );

with 'Fey::Role::SQL::Cloneable';

sub delete { return $_[0] }

sub from
{
    my $self     = shift;

    my $count = @_ ? @_ : 1;
    my (@tables) = pos_validated_list( \@_, 
                                       ( ( { isa => 'Fey::Table' } ) x $count ),
                                       MX_PARAMS_VALIDATE_NO_CACHE => 1,
                                     );

    $self->_set_from(\@tables);

    return $self;
}

sub sql
{
    my $self  = shift;
    my ($dbh) = pos_validated_list( \@_, { isa => 'Fey::Types::CanQuote' } );

    return ( join ' ',
             $self->delete_clause($dbh),
             $self->where_clause($dbh),
             $self->order_by_clause($dbh),
             $self->limit_clause($dbh),
           );
}

sub delete_clause
{
    return 'DELETE FROM ' . $_[0]->_tables_subclause( $_[1] );
}

sub _tables_subclause
{
    return ( join ', ',
             map { $_[1]->quote_identifier( $_->name() ) }
             @{ $_[0]->_from() }
           );
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Fey::SQL::Delete - Represents a DELETE query

=head1 SYNOPSIS

  my $sql = Fey::SQL->new_delete();

  # DELETE FROM Part
  #       WHERE Part.name LIKE '%Widget'
  $sql->delete();
  $sql->from($Part);
  $sql->where( $name, 'LIKE', '%Widget' );

  print $sql->sql($dbh);

=head1 DESCRIPTION

This class represents a C<DELETE> query.

=head1 METHODS

This class provides the following methods:

=head2 Constructor

To construct an object of this class, call C<< $query->delete() >> on
a C<Fey::SQL> object.

=head2 $delete->delete()

This method is basically a no-op that exists to so that L<Fey::SQL>
has something to call after it constructs an object in this class.

=head2 $delete->from(...)

This method specifies the C<FROM> clause of the query. It expects one
or more L<Fey::Table> objects (not aliases). Most RDBMS
implementations only allow for a single table here, but some (like
MySQL) do allow for multi-table deletes.

=head2 $delete->where(...)

See the L<Fey::SQL section on WHERE Clauses|Fey::SQL/WHERE Clauses>
for more details.

=head2 $delete->order_by(...)

See the L<Fey::SQL section on ORDER BY Clauses|Fey::SQL/ORDER BY
Clauses> for more details.

=head2 $delete->limit(...)

See the L<Fey::SQL section on LIMIT Clauses|Fey::SQL/LIMIT Clauses>
for more details.

=head2 $delete->sql()

Returns the full SQL statement which this object represents. A DBI
handle must be passed so that identifiers can be properly quoted.

=head2 $delete->bind_params()

See the L<Fey::SQL section on Bind Parameters|Fey::SQL/Bind
Parameters> for more details.

=head2 $delete->delete_clause()

Returns the C<DELETE> clause portion of the SQL statement as a string.

=head2 $delete->where_clause()

Returns the C<WHERE> clause portion of the SQL statement as a string.

=head2 $delete->order_by_clause()

Returns the C<ORDER BY> clause portion of the SQL statement as a
string.

=head2 $delete->limit_clause()

Returns the C<LIMIT> clause portion of the SQL statement as a string.

=head1 ROLES

=over 4

=item * L<Fey::Role::SQL::HasBindParams>

=item * L<Fey::Role::SQL::HasWhereClause>

=item * L<Fey::Role::SQL::HasOrderByClause>

=item * L<Fey::Role::SQL::HasLimitClause>

=item * L<Fey::Role::SQL::Cloneable>

=back

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
