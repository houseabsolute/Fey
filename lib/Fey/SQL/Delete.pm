package Fey::SQL::Delete;

use strict;
use warnings;

use base 'Fey::SQL';

use Class::Trait ( 'Fey::Trait::SQL::HasWhereClause',
                   'Fey::Trait::SQL::HasOrderByClause',
                   'Fey::Trait::SQL::HasLimitClause',
                 );

use Fey::Validate
    qw( validate
        validate_pos
        SCALAR
        UNDEF
        OBJECT
      );

use Scalar::Util qw( blessed );


sub delete { return $_[0] }

{
    my $spec = { type => OBJECT,
                 callbacks =>
                 { 'is a (non-alias) table' =>
                   sub {    $_[0]->isa('Fey::Table')
                         && ! $_[0]->is_alias() },
                 },
               };

    sub from
    {
        my $self     = shift;

        my $count = @_ ? @_ : 1;
        my (@tables) = validate_pos( @_, ($spec) x $count );

        $self->{tables} = \@tables;

        return $self;
    }
}

sub sql
{
    my $self = shift;

    return ( join ' ',
             $self->_delete_clause(),
             $self->_where_clause(),
             $self->_order_by_clause(),
             $self->_limit_clause(),
           );
}

sub _delete_clause
{
    return 'DELETE FROM ' . $_[0]->_tables_subclause();
}

sub _tables_subclause
{
    return ( join ', ',
             map { $_[0]->quoter()->quote_identifier( $_->name() ) }
             @{ $_[0]->{tables} }
           );
}


1;

__END__

=head1 NAME

Fey::SQL::Delete - Represents a DELETE query

=head1 SYNOPSIS

  my $sql = Fey::SQL->new( dbh => $dbh );

  # DELETE FROM Part
  #       WHERE Part.name LIKE '%Widget'
  $sql->delete();
  $sql->from($Part);
  $sql->where( $name, 'LIKE', '%Widget' );

=head1 DESCRIPTOIN

This class represents a C<DELETE> query.

=head1 METHODS

This class provides the following methods:

=head2 Constructor

To construct an object of this class, call C<< $query->delete() >> on
a C<Fey::SQL> object.

=head2 $delete->delete()

This method is basically a no-op that exists to so that L<Fey::SQL>
has something to call after it constructs an object in this class.

=head2 $query->from(...)

This method specifies the C<FROM> clause of the query. It can accept a
variety of argument lists.

This method expects one or more L<Fey::Table> objects (not
aliases). Most RDBMS implementations only allow for a single table
here, but some (like MySQL) do allow for multi-table deletes.

=head2 $query->where(...)

See the L<Fey::SQL section on WHERE Clauses|Fey::SQL/WHERE Clauses>
for more details.

=head2 $query->order_by(...)

See the L<Fey::SQL section on ORDER BY Clauses|Fey::SQL/ORDER BY
Clauses> for more details.

=head2 $query->limit(...)

See the L<Fey::SQL section on LIMIT Clauses|Fey::SQL/LIMIT Clauses>
for more details.

=head2 $query->sql()

Returns the full SQL statement which this object represents.

=head1 TRAITS

This class does
C<Fey::Trait::SQL::HasWhereClause>,
C<Fey::Trait::SQL::HasOrderByClause>, and
C<Fey::Trait::SQL::HasLimitClause> traits.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
