package Q::Query::Fragment::Where::Comparison;

use strict;
use warnings;


use Q::Exceptions qw( param_error );
use Q::Validate
    qw( validate_pos
        SCALAR_TYPE
        UNDEF
        SCALAR
        OBJECT
      );
use Scalar::Util qw( blessed );

use Q::Query::Fragment::SubSelect;
use Q::Literal::Term;

use constant LHS  => 0;
use constant COMP => 1;
use constant RHS  => 2;

our $eq_comp_re = qr/^(?:=|!=|<>)$/;
our $in_comp_re = qr/^(?:not\s+)?in$/i;

{
    my $comparable = 
        { type      => UNDEF|SCALAR|OBJECT,
          callbacks =>
          { 'is comparable' =>
            sub {    ! blessed $_[0]
                  || (    $_[0]->can('is_comparable')
                       && $_[0]->is_comparable()
                     ) },
          },
        };

    my $operator = SCALAR_TYPE;

    sub new
    {
        my $class = shift;
        my $rhs_count = @_ - 2;
        $rhs_count = 1 if $rhs_count < 1;

        my ( $lhs, $comp, @rhs ) =
            validate_pos( @_, $comparable, $operator, ($comparable) x $rhs_count );

        for ( $lhs, @rhs )
        {
            $_ = Q::Literal->new_from_scalar($_)
                unless blessed $_;
            $_ = Q::Query::Fragment::SubSelect->new($_)
                if $_->isa('Q::Query::Select');
        }
        if ( grep { $_->isa('Q::Query::Fragment::SubSelect') } @rhs )
        {
            param_error "Cannot use a subselect on the right-hand side with $comp"
                unless $comp =~ $in_comp_re;
        }

        if ( lc $comp eq 'between' )
        {
            param_error "The BETWEEN operator requires two arguments"
                unless @rhs == 2;
        }

        if ( @rhs > 1 )
        {
            param_error "Cannot pass more than one right-hand side argument with $comp"
                unless $comp =~ /^(?:$in_comp_re|between)$/i;
        }

        return bless [ $lhs, $comp, \@rhs ], $class;
    }
}

sub sql
{
    my $sql = $_[0][LHS]->sql_or_alias( $_[1] );

    if (    $_[0][COMP] =~ $eq_comp_re
         && $_[0][RHS][0]->isa('Q::Literal::Null') )
    {
        return
            (   $sql
              . (   $_[0][COMP] eq '='
                  ? ' IS NULL'
                  : ' IS NOT NULL'
                )
            );
    }

    if ( lc $_[0][COMP] eq 'between' )
    {
        return
            (   $sql
              . ' BETWEEN '
              . $_[0][RHS][0]->sql_or_alias( $_[1] )
              . ' AND '
              . $_[0][RHS][1]->sql_or_alias( $_[1] )
            );
    }

    if ( $_[0][COMP] =~ $in_comp_re )
    {
        return
            (   $sql
              . ' '
              . ( uc $_[0][COMP] )
              . ' ('
              . ( join ', ',
                  map { $_->sql_or_alias( $_[1] ) }
                  @{ $_[0][RHS] }
                )
              . ')'
            );
    }

    return
        (   $sql
          . ' '
          . $_[0][COMP]
          . ' '
          . $_[0][RHS][0]->sql_or_alias( $_[1] )
        );
}


1;

__END__
