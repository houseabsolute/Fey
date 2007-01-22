package Fey::Query;

use strict;
use warnings;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_ro_accessors
    ( qw( dbh quoter ) );

use Fey::Exceptions qw( param_error virtual_method );
use Fey::Validate
    qw( validate
        DBI_TYPE
      );

use Scalar::Util qw( blessed );

use Fey::Query::Delete;
use Fey::Query::Insert;
use Fey::Query::Select;
use Fey::Query::Update;
use Fey::Query::Where;

use Fey::Placeholder;
use Fey::Quoter;


{
    my $spec = { dbh => DBI_TYPE };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $quoter = Fey::Quoter->new( dbh => $p{dbh} );

        return bless { %p,
                       quoter => $quoter,
                     }, $class;
    }
}

sub select
{
    my $self = shift;

    $self->_rebless_for( 'select', @_ );
}

sub insert
{
    my $self = shift;

    return $self->_rebless_for( 'insert', @_ );
}

sub update
{
    my $self = shift;

    $self->_rebless_for( 'update', @_ );
}

sub delete
{
    my $self = shift;

    $self->_rebless_for( 'delete', @_ );
}

sub where
{
    my $self = shift;

    $self->_rebless_for( 'where', @_ );
}

sub _rebless_for
{
    my $self = shift;
    my $type = shift;

    my $class = (ref $self) . '::' . ucfirst $type;

    my $new = $class->new( dbh => $self->dbh() );

    %$self = %$new;

    bless $self, ref $new;

    return $self->$type(@_);
}


1;

__END__

=head1 NAME

Fey::Query - A superclass for all types of SQL queries

=head1 SYNOPSIS

  my $query = Fey::Query->new( dbh => $dbh );

  $query->select( @columns );

=head1 DESCRIPTION

This class provides the primary interface for generating SQL
queries. All queries start with a C<Fey::Query> object, and are then
transformed into a more specific subclass when the appropriate method
is called.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Query->new( dbh => $dbh )

This method creates a new C<Fey::Query> object. It requires a
parameter named "dbh", which must be a DBI handle.

=head2 $query->select(...)

=head2 $query->update(...)

=head2 $query->insert(...)

=head2 $query->delete(...)

These methods re-bless the query into the proper C<Fey::Query>
subclass, and then call the specified method on the newly re-blessed
object. Any parameters passed to this method will be passed on in the
second call.

See L<Fey::Query::Select>, L<Fey::Query::Update>,
L<Fey::Query::Insert>, and L<Fey::Query::Delete> for more details.

=head2 $query->where(...)

This produces a C<Fey::Query::Where> object, which is an object that
just contains a where clause. This exists to allow you to add where
clauses to joins. See the documentation on L<<
Fey::Query::Select->from()|Fey::Query::Select/$query->from()/ >> for
more details.

=head1 WHERE CLAUSES

Many types of queries allow C<WHERE> clauses via the a C<where()>
method. The method accepts several different types of parameters:

=head2 Comparisons

These all a similar form:

  # WHERE Part.size = $value}
  $query->where( $size, '=', $value );

  # WHERE Part.size = AVG(Part.size);
  $query->where( $size, '=', $avg_size_function );

  # WHERE Part.size = ?
  $query->where( $size, '=', $placeholder );

  # WHERE User.user_id = Message.user_id
  $query->where( $user_id, '=', $other_user_id );

The left-hand side of a conditional does not need to be a column
object, it could be a function or anything that produces valid SQL.

  my $length = Fey::Literal::Function->new( 'LENGTH', $name );
  # WHERE LENGTH(Part.name) = 10
  $query->where( $length, '=', 10 );

The second parameter in a conditional can be anything that produces
valid SQL:

  # WHERE Message.body LIKE 'hello%'
  $query->where( $body, 'LIKE', 'hello%' );

  # WHERE Part.quantity > 10
  $query->where( $quantity, '>', 10 );

If you use a comparison operator like C<BETWEEN> or C<(NOT) IN>, you
can pass more than three parameters to C<where()>.

  # WHERE Part.size BETWEEN 4 AND 10
  $query->where( $size, 'BETWEEN', 4, 10 );

  # WHERE User.user_id IN (1, 2, 7, 9)
  $query->where( $user_id, 'IN', 1, 2, 7, 9 );

You can also pass a subselect when using C<IN>.

  my $select = $query->select(...);

  # WHERE User.user_id IN ( SELECT user_id FROM ... )
  $query->where( $user_id, 'IN', $select );

If you use C<=>, C<!=>, or C<< <> >> as the comparison and the
right-hand side is C<undef>, then the generated query will use C<IS
NULL> or C<IS NOT NULL>, as appropriate:

  # WHERE Part.name IS NULL
  $query->where( $name, '=', undef );

  # WHERE Part.name IS NOT NULL
  $query->where( $name, '!=', undef );

Note that if you use a placeholder object in this case, then the query
will not be transformed into an C<IS (NOT) NULL> expression, since the
value of the placeholder is not known when the SQL is being generated.

=head2 Boolean Combinations

You can pass the strings "and" and "or" to the C<where()> method in
order to create complex boolean checks. When you call C<where()> with
multiple comparisons in a row, an implicit "and" is added between each
one.

  # WHERE Part.size > 10 OR Part.size = 5
  $query->where( $size, '>', 10 );
  $query->where( 'or' );
  $query->where( $size, '=', 5 );

  # WHERE Part.size > 10 AND Part.size < 20
  $query->where( $size, '>', 10 );
  # there is an implicit $query->where( 'and' ) here ...
  $query->where( $size, '<', 10 );

=head2 Subgroups

You can pass the strings "(" and ")" to the C<where()> method in order
to create subgroups.

  # WHERE Part.size > 10
  #   AND ( User.name = 'Widget'
  #         OR
  #         User.name = 'Grommit' )
  $query->where( $size, '>', 10 );
  $query->where( '(' );
  $query->where( $name, '=', 'Widget' );
  $query->where( 'or' );
  $query->where( $name, '=', 'Grommit' );
  $query->where( ')' );

=head1 ORDER BY CLAUSES

Many types of queries allow C<ORDER BY> clauses via the an
C<order_by()> method. This method accepts a list of items. The items
in the list may be things to order by, or sort directions. The things
you can order by are columns (including aliases), functions, and
terms. You may follow one of these with a sort direction, which must
be one of C<'ASC'> or C<'DESC'> (case-insensitive).

  # ORDER BY Part.size
  $query->order_by( $size );

  # ORDER BY Part.size DESC
  $query->order_by( $size, 'DESC' );

  # ORDER BY Part.size DESC, Part.name ASC
  $query->order_by( $size, 'DESC', $name, 'ASC' );

  my $length = Fey::Literal::Function->new( 'LENGTH', $name );
  # ORDER BY LENGTH( Part.name ) ASC
  $query->order_by( $length, 'ASC' );

If you pass a function literal, and that literal has an alias, then
the alias is used in the C<ORDER BY> clause.


  my $length = Fey::Literal::Function->new( 'LENGTH', $name );
  $query->select($length);

  # SELECT LENGTH(Part.name) AS FUNCTION0 ...
  # ORDER BY FUNCTION0 ASC
  $query->order_by( $length, 'ASC' );

=head1 LIMIT CLAUSES

Many types of queries allow C<LIMIT> clauses via the an C<limit()>
method. This method accepts two parameters, with the second being
optional.

The first parameter is the number of items. The second, optional
parameter, is the offset for the limit clause.

  # LIMIT 10
  $query->limit( 10 );

  # LIMIT 10 OFFSET 20
  $query->limit( 10, 20 );

  # LIMIT 0 OFFSET 20
  $query->limit( 0, 20 );

=cut
