package Fey::SQL;

use strict;
use warnings;

use Fey::SQL::Delete;
use Fey::SQL::Insert;
use Fey::SQL::Select;
use Fey::SQL::Update;
use Fey::SQL::Where;


1;

__END__

=head1 NAME

Fey::SQL - Documentation on SQL generation with Fey

=head1 SYNOPSIS

  my $sql = Fey::SQL::Select->new( dbh => $dbh );

  $sql->select( @columns );

=head1 DESCRIPTION

This module mostly exists to provide documentation.

For convenience, loading this module loads all of the C<Fey::SQL::*>
classes, such as L<Fey::SQL::Select>, L<Fey::SQL::Delete>, etc.

=head1 CREATING SQL

This documentation covers the clauses in SQL queries which are shared
across different types of queries, including C<WHERE>, C<ORDER BY>,
and C<LIMIT>. For SQL clauses that are specific to one type of query,
see the appropriate subclass. For example, for C<SELECT> clauses, see
the L<Fey::SQL::Select> class documentation.

=head2 WHERE Clauses

Many types of queries allow C<WHERE> clauses via the a C<where()>
method. The method accepts several different types of parameters:

=head3 Comparisons

These all a similar form:

  # WHERE Part.size = $value}
  $sql->where( $size, '=', $value );

  # WHERE Part.size = AVG(Part.size);
  $sql->where( $size, '=', $avg_size_function );

  # WHERE Part.size = ?
  $sql->where( $size, '=', $placeholder );

  # WHERE User.user_id = Message.user_id
  $sql->where( $user_id, '=', $other_user_id );

The left-hand side of a conditional does not need to be a column
object, it could be a function or anything that produces valid SQL.

  my $length = Fey::Literal::Function->new( 'LENGTH', $name );
  # WHERE LENGTH(Part.name) = 10
  $sql->where( $length, '=', 10 );

The second parameter in a conditional can be anything that produces
valid SQL:

  # WHERE Message.body LIKE 'hello%'
  $sql->where( $body, 'LIKE', 'hello%' );

  # WHERE Part.quantity > 10
  $sql->where( $quantity, '>', 10 );

If you use a comparison operator like C<BETWEEN> or C<(NOT) IN>, you
can pass more than three parameters to C<where()>.

  # WHERE Part.size BETWEEN 4 AND 10
  $sql->where( $size, 'BETWEEN', 4, 10 );

  # WHERE User.user_id IN (1, 2, 7, 9)
  $sql->where( $user_id, 'IN', 1, 2, 7, 9 );

You can also pass a subselect when using C<IN>.

  my $select = $sql->select(...);

  # WHERE User.user_id IN ( SELECT user_id FROM ... )
  $sql->where( $user_id, 'IN', $select );

If you use C<=>, C<!=>, or C<< <> >> as the comparison and the
right-hand side is C<undef>, then the generated query will use C<IS
NULL> or C<IS NOT NULL>, as appropriate:

  # WHERE Part.name IS NULL
  $sql->where( $name, '=', undef );

  # WHERE Part.name IS NOT NULL
  $sql->where( $name, '!=', undef );

Note that if you use a placeholder object in this case, then the query
will not be transformed into an C<IS (NOT) NULL> expression, since the
value of the placeholder is not known when the SQL is being generated.

=head3 Boolean AND/OR

You can pass the strings "and" and "or" to the C<where()> method in
order to create complex boolean checks. When you call C<where()> with
multiple comparisons in a row, an implicit "and" is added between each
one.

  # WHERE Part.size > 10 OR Part.size = 5
  $sql->where( $size, '>', 10 );
  $sql->where( 'or' );
  $sql->where( $size, '=', 5 );

  # WHERE Part.size > 10 AND Part.size < 20
  $sql->where( $size, '>', 10 );
  # there is an implicit $sql->where( 'and' ) here ...
  $sql->where( $size, '<', 10 );

=head2 Subgroups

You can pass the strings "(" and ")" to the C<where()> method in order
to create subgroups.

  # WHERE Part.size > 10
  #   AND ( User.name = 'Widget'
  #         OR
  #         User.name = 'Grommit' )
  $sql->where( $size, '>', 10 );
  $sql->where( '(' );
  $sql->where( $name, '=', 'Widget' );
  $sql->where( 'or' );
  $sql->where( $name, '=', 'Grommit' );
  $sql->where( ')' );

=head2 ORDER BY Clauses

Many types of queries allow C<ORDER BY> clauses via the an
C<order_by()> method. This method accepts a list of items. The items
in the list may be things to order by, or sort directions. The things
you can order by are columns (including aliases), functions, and
terms. You may follow one of these with a sort direction, which must
be one of C<'ASC'> or C<'DESC'> (case-insensitive).

  # ORDER BY Part.size
  $sql->order_by( $size );

  # ORDER BY Part.size DESC
  $sql->order_by( $size, 'DESC' );

  # ORDER BY Part.size DESC, Part.name ASC
  $sql->order_by( $size, 'DESC', $name, 'ASC' );

  my $length = Fey::Literal::Function->new( 'LENGTH', $name );
  # ORDER BY LENGTH( Part.name ) ASC
  $sql->order_by( $length, 'ASC' );

If you pass a function literal, and that literal has an alias, then
the alias is used in the C<ORDER BY> clause.

  my $length = Fey::Literal::Function->new( 'LENGTH', $name );
  $sql->select($length);

  # SELECT LENGTH(Part.name) AS FUNCTION0 ...
  # ORDER BY FUNCTION0 ASC
  $sql->order_by( $length, 'ASC' );

=head2 LIMIT Clauses

Many types of queries allow C<LIMIT> clauses via the an C<limit()>
method. This method accepts two parameters, with the second being
optional.

The first parameter is the number of items. The second, optional
parameter, is the offset for the limit clause.

  # LIMIT 10
  $sql->limit( 10 );

  # LIMIT 10 OFFSET 20
  $sql->limit( 10, 20 );

  # LIMIT 0 OFFSET 20
  $sql->limit( 0, 20 );

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
