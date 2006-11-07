package Q::Query::Fragment::Where::Comparison;

use strict;
use warnings;


use Q::Exceptions qw( param_error );
use Q::Validate
    qw( validate_pos
        SCALAR_TYPE
        SCALAR
        OBJECT
      );
use Scalar::Util qw( blessed );

use Q::Query::Fragment::SubSelect;
use Q::Literal::Term;

use constant LHS  => 0;
use constant COMP => 1;
use constant RHS  => 2;

our $eq_comp_re = qr/(?:=|!=|<>)/;
our $in_comp_re = qr/(?:not\s+)?in/;

{
    my @spec =
        ( { type      => SCALAR|OBJECT,
            callbacks =>
            { 'column (with table) or literal' =>
              sub {    ! blessed $_[0]
                    || $_[0]->isa('Q::Literal')
                    || ( $_[0]->isa('Q::Column')
                         && $_[0]->table() ) },
            },
          },
          SCALAR_TYPE,
        );
    my $rhs =
        ( { type      => SCALAR|OBJECT,
            callbacks =>
            { 'column (with table), literal, placeholder, or select' =>
              sub {    ! blessed $_[0]
                    || $_[0]->isa('Q::Literal')
                    || ( $_[0]->isa('Q::Column')
                         && $_[0]->table() )
                    || $_[0]->isa('Q::Placeholder')
                    || $_[0]->isa('Q::Query::Select') },
            },
          } );
    sub new
    {
        my $class = shift;
        my $rhs_count = @_ - 2;
        $rhs_count = 1 if $rhs_count < 1;
        my ( $lhs, $comp, @rhs ) = validate_pos( @_, @spec, ($rhs) x $rhs_count );

        if ( ! $rhs[0] )
        {
            param_error "Cannot pass undef as right hand side of where with $comp"
                unless $comp =~ /$eq_comp_re/;
        }

        if ( grep { blessed $_ && $_->isa('Q::Query::Fragment::Subselect') } @rhs )
        {
            param_error "Cannot use a subselect on the right-hand side with $comp"
                unless $comp =~ /^$in_comp_re$/i;
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

        param_error "Must pass at least one right-hand side argument for a where clause"
            unless @rhs;

        for ( $lhs, @rhs )
        {
            $_ = Q::Literal->new_from_scalar($_)
                unless blessed $_;
            $_ = Q::Query::Fragment::SubSelect->new($_)
                if $_->isa('Q::Query::Select');
        }

        return bless [ $lhs, $comp, \@rhs ], $class;
    }
}

sub as_sql
{
    my $sql = $_[1]->_lhs_for_where( $_[0][LHS] );

    if (    $_[0][COMP] =~ /^$eq_comp_re$/
         && ! defined $_[0][RHS][0] )
    {
        return
            (   $sql
              . $_[0][COMP] == '='
                ? ' IS NULL'
                : ' IS NOT NULL'
            );
    }

    if ( lc $_[0][COMP] eq 'between' )
    {
        return
            (   $sql
              . ' BETWEEN '
              . $_[1]->_rhs_for_where( $_[0][RHS][0] )
              . ' AND '
              . $_[1]->_rhs_for_where( $_[0][RHS][1] )
            );
    }

    if ( $_[0][COMP] =~ /^$in_comp_re$/ )
    {
        return
            (   $sql
              . ' '
              . uc $_[0][COMP]
              . ' ('
              . ( join ', ',
                  map { $_[1]->_rhs_for_where( $_[0] ) }
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
          . $_[1]->_rhs_for_where( $_[0][RHS][0] )
        );
}


1;

__END__