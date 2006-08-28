package Q::Query::Select;

use strict;
use warnings;

use base 'Q::Query';

__PACKAGE__->mk_ro_accessors
    ( qw( is_distinct ) );

use Q::Exceptions qw( object_state_error param_error );
use Q::Validate
    qw( validate_pos
        SCALAR
        OBJECT
      );

use Q::Literal;
use Scalar::Util qw( blessed );


{
    my $spec = { type      => SCALAR|OBJECT,
                 callbacks =>
                 { 'table, alias, literal, column, or scalar' =>
                   sub {    ! blessed $_[0]
                         || $_[0]->isa('Q::Table')
                         || $_[0]->isa('Q::Literal')
                         || (    $_[0]->isa('Q::Column')
                              && $_[0]->table() ) },
                 },
               };
    sub select
    {
        my $self = shift;
        my @s    = validate_pos( @_, ($spec) x @_ );

        for my $elt ( map { $_->can('columns')
                            ? sort { $a->name() cmp $b->name() } $_->columns()
                           : $_ }
                      map { blessed $_ ? $_ : Q::Literal::Term->new($_) }
                      @s )
        {
            my $key = $elt->can('id') ? $elt->id() : $self->format_literal($elt);
            $self->{select}{$key} = $elt;
        }

        return $self;
    }
}

sub distinct
{
    $_[0]->{is_distinct} = 1;

    return $_[0];
}

{
    sub from
    {
        my $self = shift;

        # gee, wouldn't multimethods be nice here?
        my $meth =
            (   @_ == 1 && blessed $_[0] && $_[0]->isa('Q::Table')
              ? '_from_one_table'
              : @_ == 1 && blessed $_[0] && $_[0]->isa('Q::Query::Select')
              ? '_from_subselect'
              : @_ == 2
              ? '_join'
              : @_ == 3 && ! blessed $_[1]
              ? '_outer_join'
              : @_ == 3
              ? '_join'
              : @_ == 4 && $_[3]->isa('Q::FK')
              ? '_outer_join'
              : @_ == 4 && $_[3]->isa('Q::Query')
              ? '_outer_join_with_where'
              : @_ == 5
              ? '_outer_join_with_where'
              : undef
            );

        param_error "from() called with invalid parameters (@_)."
            unless $meth;

        $self->$meth(@_);

        return $self;
    }
}

sub _from_one_table
{
    my $self = shift;

    my $join = Q::QueryFragment::Join->new( $_[0] );
    $self->{from}{ $join->id() } = $join;
}

sub _from_subselect
{
    my $self = shift;

    my $subsel = Q::QueryFragment::SubSelect->new( $_[0] );
    $self->{from}{ $subsel->id() } = $subsel;
}

sub _join
{
    my $self = shift;

    param_error 'from() was called with with an invalid first two arguments.'
        unless $_[0]->isa('Q::Table') && $_[1]->isa('Q::Table');

    my $fk = $_[2] || $self->_fk_for_join(@_);

    my $key = join "\0", sort map { $_->id() } @_[0,1], $fk;

    my $join = Q::QueryFragment::Join->new( @_[0,1], $fk );
    $self->{from}{ $join->id() } = $join;
}

sub _fk_for_join
{
    my $self = shift;

    my $s  = $_[0]->schema;
    my @fk = $s->foreign_keys_between_tables(@_);

    unless ( @fk == 1 )
    {
        param_error 'You specified a join for two tables that do not share a foreign key.'
            unless @fk;

        param_error
              'You specified a join for two tables with more than one foreign key,'
            . ', so you must specify which foreign key to use for the join.';
    }

    return $fk[0];
}

sub _outer_join
{
    my $self = shift;

    _check_outer_join_arguments(@_);

    my $fk = $_[3] || $self->_fk_for_join( @_[0, 2] );

    my $join = Q::QueryFragment::Join->new( @_[0, 2], $fk, $_[1] );
    $self->{from}{ $join->id() } = $join;
}

sub _outer_join_with_where
{
    my $self = shift;

    _check_outer_join_arguments(@_);

    my $fk = $_[3] || $self->_fk_for_join( @_[0, 2] );

    my $join = Q::QueryFragment::Join->new( @_[0, 2], $fk, $_[1], $_[4] );
    $self->{from}{ $join->id() } = $join;
}

sub _check_outer_join_arguments
{
    param_error 'invalid outer join type, must be one of out left, right, or full.'
        unless $_[1] =~ /^(?:left|right|full)$/;

    param_error 'from() was called with invalid arguments'
        unless $_[0]->isa('Q::Table') && $_[2]->isa('Q::Table');
}

sub as_sql
{
    my $self = shift;

    return
        ( join ' ',
          $self->_select_clause(),
          $self->_from_clause(),
          $self->_where_clause(),
          $self->_group_by_clause(),
          $self->_order_by_clause(),
          $self->_limit_clause(),
        );
}

sub _select_clause
{
    my $self = shift;

    my $sql = 'SELECT ';
    $sql .= 'DISTINCT ' if $self->is_distinct();
    $sql .=
        ( join ', ',
          map { $self->_format_column_or_literal( $self->{select}{$_} ) }
          sort
          keys %{ $self->{select} }
        );

    return $sql;
}

sub _from_clause
{
    my $self = shift;

    # The sort means that the order that things appear in will be
    # repeatable, if not obvious.
    my @from;
    for my $j ( map { $self->{from}{$_} } sort keys %{ $self->{from} } )
    {
        push @from, $j->as_sql($self);
    }

    return 'FROM ' . join ', ', @from;
}


package Q::QueryFragment::Join;

use List::MoreUtils qw( pairwise );

use constant TABLE1 => 0;
use constant TABLE2 => 1;
use constant FK     => 2;
use constant OUTER  => 3;
use constant WHERE  => 4;


sub new
{
    my $class = shift;

    return bless \@_, $class;
}

sub id
{
    # This is a rather special case, and handling it separately makes
    # the rest of this method simpler.
    return $_[0]->[TABLE1]->id()
        unless $_[0]->[TABLE2];

    my ( $t1, $t2 ) =
        ( $_[0]->[OUTER] && $_[0]->[OUTER] ne 'full'
          ? @{ $_[0] }[ TABLE1, TABLE2 ]
          : ( sort { $a->name() cmp $b->name() }
              @{ $_[0] }[ TABLE1, TABLE2 ] )
        );

    return
        ( join "\0",
          $_[0]->[OUTER] || (),
          $t1->id(),
          $t2->id(),
          $_[0]->[FK]->id(),
        );
}

sub as_sql
{
    return $_[1]->_table_name_with_alias( $_[0]->[TABLE1] )
        unless $_[0]->[TABLE2];

    my $join = $_[1]->_table_name_with_alias( $_[0]->[TABLE1] );
    if ( $_[0]->[OUTER] )
    {
        $join .= ' ' . uc $_[0]->[OUTER] . ' OUTER';
    }
    $join .= ' JOIN ';
    $join .= $_[1]->_table_name_with_alias( $_[0]->[TABLE2] );
    $join .= ' ON ';

    my @s = $_[0]->[FK]->source_columns();
    my @t = $_[0]->[FK]->target_columns();

    for my $p ( pairwise { [ $a, $b ] } @s, @t )
    {
        $join .= $_[1]->_fq_column_name( $p->[0] );
        $join .= ' = ';
        $join .= $_[1]->_fq_column_name( $p->[1] );
    }

    if ( $_[0]->[WHERE] )
    {

    }

    return $join;
}

package Q::QueryFragment::SubSelect;


use constant SELECT  => 0;
use constant COUNTER => 1;

my $Counter = 0;
sub new
{
    my $class  = shift;
    my $select = shift;

    return bless [ $select, $Counter++ ], $class;
}

sub id { $_[0][SELECT]->as_sql() }

sub as_sql
{
    return '( ' . $_[0][SELECT]->as_sql() . ' ) AS SUBSELECT' . $_[0]->[COUNTER];
}


1;

__END__
