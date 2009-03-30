package Fey::SQL;

use strict;
use warnings;

use Fey::SQL::Delete;
use Fey::SQL::Insert;
use Fey::SQL::Select;
use Fey::SQL::Update;
use Fey::SQL::Where;
use Fey::SQL::Union;
use Fey::SQL::Intersect;
use Fey::SQL::Except;
use Fey::Types;


sub new_delete
{
    shift;
    return Fey::SQL::Delete->new(@_);
}

sub new_insert
{
    shift;
    return Fey::SQL::Insert->new(@_);
}

sub new_select
{
    shift;
    return Fey::SQL::Select->new(@_);
}

sub new_update
{
    shift;
    return Fey::SQL::Update->new(@_);
}

sub new_where
{
    shift;
    return Fey::SQL::Where->new(@_);
}

sub new_union
{
    shift;
    return Fey::SQL::Union->new(@_);
}

sub new_intersect
{
    shift;
    return Fey::SQL::Intersect->new(@_);
}

sub new_except
{
    shift;
    return Fey::SQL::Except->new(@_);
}

1;

__END__

=head1 NAME

Fey::SQL - Documentation on SQL generation with Fey and SQL object factory

=head1 SYNOPSIS

  my $sql = Fey::SQL->new_select();

  $sql->select( @columns );

=head1 DESCRIPTION

This module mostly exists to provide documentation and a factory
interface for making SQL statement objects.

For convenience, loading this module loads all of the C<Fey::SQL::*>
classes, such as L<Fey::SQL::Select>, L<Fey::SQL::Delete>, etc.

=head1 METHODS

This class acts as a factory for the various SQL statement classes,
such as L<Fey::SQL::Select> or L<Fey::SQL::Update>. This is simply
sugar which makes it easy to replace C<Fey::SQL> with a subclass,
either for your application or for a specific DBMS.

=head2 Fey::SQL->new_select()

Returns a new C<Fey::SQL::Select> object.

=head2 Fey::SQL->new_insert()

Returns a new C<Fey::SQL::Insert> object.

=head2 Fey::SQL->new_update()

Returns a new C<Fey::SQL::Update> object.

=head2 Fey::SQL->new_delete()

Returns a new C<Fey::SQL::Delete> object.

=head2 Fey::SQL->new_where()

Returns a new C<Fey::SQL::Where> object.

=head2 Fey::SQL->new_union()

Returns a new C<Fey::SQL::Union> object.

=head2 Fey::SQL->new_intersect()

Returns a new C<Fey::SQL::Intersect> object.

=head2 Fey::SQL->new_except()

Returns a new C<Fey::SQL::Except> object.

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

Comparing a column to a given value ...

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

The second parameter in a conditional can any comparison operator that
produces valid SQL:

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

You can also use C<and()> instead of where if you like the look ...

  $sql->where( $size, '=', $value )
      ->and  ( $quantity, '>', 10 );

The C<and()> method is just sugar, since by default, multiple calls to
C<where()> end up concatenated with an C<AND> in the resulting SQL.

=head3 Boolean AND/OR

You can pass the strings "and" and "or" to the C<where()> method in
order to create complex boolean conditions. When you call C<where()>
with multiple comparisons in a row, an implicit "and" is added between
each one.

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

Many types of queries allow C<ORDER BY> clauses via the C<order_by()>
method. This method accepts a list of items. The items in the list may
be columns, functions, terms, or sort directions ("ASC" or
"DESC"). The sort direction can also specify "NULLS FIRST" or "NULLS
LAST".

  # ORDER BY Part.size
  $sql->order_by( $size );

  # ORDER BY Part.size DESC
  $sql->order_by( $size, 'DESC' );

  # ORDER BY Part.size DESC, Part.name ASC
  $sql->order_by( $size, 'DESC', $name, 'ASC' );

  # ORDER BY Part.size ASC NULLS FIRST
  $sql->order_by( $size, 'ASC NULLS FIRST' );

  my $length = Fey::Literal::Function->new( 'LENGTH', $name );
  # ORDER BY LENGTH( Part.name ) ASC
  $sql->order_by( $length, 'ASC' );

If you pass a function literal to the C<order_by()> method and the
literal was used previously in the select clause, then an alias is
used in the C<ORDER BY> clause.

  my $length = Fey::Literal::Function->new( 'LENGTH', $name );
  $sql->select($length);

  # SELECT LENGTH(Part.name) AS FUNCTION0 ...
  # ORDER BY FUNCTION0 ASC
  $sql->order_by( $length, 'ASC' );

=head2 LIMIT Clauses

Many types of queries allow C<LIMIT> clauses via the C<limit()>
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

=head2 Bind Parameters

By default, whenever you pass a non-object value where a placeholder
could go, the SQL class replaces this with a placeholder and stores
the value as a bind parameter. This applies to things like C<WHERE>
and C<HAVING> clauses, as well as the C<VALUES> clause of an
C<INSERT>, and the C<SET> clause of an C<UPDATE>.

You can retrieve the bind parameters by calling C<<
$sql->bind_params() >>. These will be returned in the proper order for
passing to C<DBI>'s C<execute()> method.

If you do not want values automatically converted to placeholders, you
can turn this behavior off by setting C<auto_placeholders> to a false
value when creating the object:

  my $select = Fey::SQL->new_select( auto_placeholders => 0 );

In this case, values will be quoted as needed and inserted directly
into the generated SQL.

=head2 Overloaded Objects as Parameters

In any place where you can pass a plain scalar, you can also pass an
overloaded object that overloads stringification or numification. This
includes C<WHERE> clause comparisons, C<VALUES> in an C<INSERT>, and
C<SET> clauses in an C<UPDATE>.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
