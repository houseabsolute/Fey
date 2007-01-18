package Fey::Query::Select;

use strict;
use warnings;

use base 'Fey::Query';

__PACKAGE__->mk_ro_accessors
    ( qw( is_distinct ) );

use Fey::Exceptions qw( param_error );
use Fey::Validate
    qw( validate_pos
        SCALAR
        OBJECT
        POS_INTEGER_TYPE
        POS_OR_ZERO_INTEGER_TYPE
      );

use Fey::Literal;
use Fey::Query::Fragment::Join;
use Fey::Query::Fragment::SubSelect;
use List::MoreUtils qw( all );
use Scalar::Util qw( blessed );


{
    my $spec = { type      => SCALAR|OBJECT,
                 callbacks =>
                 { 'is selectable' =>
                   sub {    ! blessed $_[0]
                         || $_[0]->isa('Fey::Table')
                         || $_[0]->isa('Fey::Table::Alias')
                         || (    $_[0]->can('is_selectable')
                              && $_[0]->is_selectable()
                            ) },
                 },
               };
    sub select
    {
        my $self = shift;
        my @s    = validate_pos( @_, ($spec) x @_ );

        for my $elt ( map { $_->can('columns')
                            ? sort { $a->name() cmp $b->name() } $_->columns()
                           : $_ }
                      map { blessed $_ ? $_ : Fey::Literal->new_from_scalar($_) }
                      @s )
        {
            $self->{select}{ $elt->id() } = $elt;
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
            (   @_ == 1 && blessed $_[0] && $_[0]->can('is_joinable') && $_[0]->is_joinable()
              ? '_from_one_table'
              : @_ == 1 && blessed $_[0] && $_[0]->isa('Fey::Query::Select')
              ? '_from_subselect'
              : @_ == 2
              ? '_join'
              : @_ == 3 && ! blessed $_[1]
              ? '_outer_join'
              : @_ == 3
              ? '_join'
              : @_ == 4 && $_[3]->isa('Fey::FK')
              ? '_outer_join'
              : @_ == 4 && $_[3]->isa('Fey::Query')
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

    my $join = Fey::Query::Fragment::Join->new( $_[0] );
    $self->{from}{ $join->id() } = $join;
}

sub _from_subselect
{
    my $self = shift;

    my $subsel = Fey::Query::Fragment::SubSelect->new( $_[0] );
    $self->{from}{ $subsel->id() } = $subsel;
}

sub _join
{
    my $self = shift;

    param_error 'from() was called with with an invalid first two arguments.'
        unless all { $_->can('is_joinable') && $_->is_joinable() } @_[0,1];

    my $fk = $_[2] || $self->_fk_for_join(@_);

    my $join = Fey::Query::Fragment::Join->new( @_[0,1], $fk );
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

    # I used to have ...
    #
    #  $_[3] || $self->_fk_for_join( @_[0, 2] )
    #
    # but this ends up reducing code coverage because it's not
    # possible (I hope) to have a situation where both are false.
    my $fk = $_[3];
    $fk = $self->_fk_for_join( @_[0, 2] )
        unless $fk;

    my $join = Fey::Query::Fragment::Join->new( @_[0, 2], $fk, lc $_[1] );
    $self->{from}{ $join->id() } = $join;
}

sub _outer_join_with_where
{
    my $self = shift;

    _check_outer_join_arguments(@_);

    my $fk;
    $fk = $_[3]->isa('Fey::FK') ? $_[3] : $self->_fk_for_join( @_[0, 2] );

    my $where = $_[4] ? $_[4] : $_[3];

    my $join = Fey::Query::Fragment::Join->new( @_[0, 2], $fk, lc $_[1], $where );
    $self->{from}{ $join->id() } = $join;
}

sub _check_outer_join_arguments
{
    param_error 'invalid outer join type, must be one of out left, right, or full.'
        unless $_[1] =~ /^(?:left|right|full)$/i;

    param_error 'from() was called with invalid arguments'
        unless $_[0]->isa('Fey::Table') && $_[2]->isa('Fey::Table');
}

{
    my $spec = { type      => SCALAR|OBJECT,
                 callbacks =>
                 { 'is groupable' =>
                   sub { $_[0]->can('is_groupable') && $_[0]->is_groupable() },
                 },
               };

    sub group_by
    {
        my $self = shift;

        my $count = @_ ? @_ : 1;
        my (@by) = validate_pos( @_, ($spec) x $count );

        push @{ $self->{group_by} }, @by;
    }
}

sub having
{
    my $self = shift;

    $self->_condition( 'having', @_ );

    return $self;
}

sub sql
{
    my $self = shift;

    return
        ( join ' ',
          $self->_select_clause(),
          $self->_from_clause(),
          $self->_where_clause(),
          $self->_group_by_clause(),
          $self->_having_clause(),
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
          map { $self->{select}{$_}->sql_with_alias( $self->quoter() ) }
          sort
          keys %{ $self->{select} }
        );

    return $sql;
}

sub _from_clause
{
    my $self = shift;

    return ( 'FROM '
             .
             ( join ', ',
               map { $self->{from}{$_}->sql_with_alias( $self->quoter() ) }
               # The sort means that the order that things appear in
               # will be repeatable, if not obvious.
               sort
               keys %{ $self->{from} }
             )
           )
}

sub _group_by_clause
{
    my $self = shift;

    return unless $self->{group_by};

    return ( 'GROUP BY '
             .
             ( join ', ',
               map { $_->sql_or_alias( $self->quoter() ) }
               @{ $self->{group_by} }
             )
           );
}

sub _having_clause
{
    return unless $_[0]->{having};

    return ( 'HAVING '
             . ( join ' ',
                 map { $_->sql( $_[0]->quoter() ) }
                 @{ $_[0]->{having} }
               )
           )
}

# REVIEW - Fakes being comparable so it will be transformed into a
# subselect fragment by query bits.
sub is_comparable { 1 }


1;

__END__
