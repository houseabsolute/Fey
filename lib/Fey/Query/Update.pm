package Fey::Query::Update;

use strict;
use warnings;

use base 'Fey::Query';

use Fey::Exceptions qw( param_error );
use Fey::Validate
    qw( validate_pos
        SCALAR
        UNDEF
        OBJECT
      );

use Fey::Literal;
use Scalar::Util qw( blessed );


{
    my $spec = { type => OBJECT,
                 callbacks =>
                 { 'is a (non-alias) table' =>
                   sub {    $_[0]->isa('Fey::Table')
                         && ! $_[0]->is_alias() },
                 },
               };

    sub update
    {
        my $self     = shift;

        my $count = @_ ? @_ : 1;
        my (@tables) = validate_pos( @_, ($spec) x $count );

        $self->{tables} = \@tables;

        return $self;
    }
}

{
    my $column_spec = { type => OBJECT,
                        callbacks =>
                        { 'is a (non-alias) column' =>
                          sub {    $_[0]->isa('Fey::Column')
                                && $_[0]->table()
                                && ! $_[0]->is_alias() },
                        },
                      };

    my $nullable_col_value_type =
        { type      => SCALAR|UNDEF|OBJECT,
          callbacks =>
          { 'literal, placeholder, column, undef, or scalar' =>
            sub {    ! blessed $_[0]
                  || ( $_[0]->isa('Fey::Column') && !$_[0]->is_alias() )
                  || $_[0]->isa('Fey::Literal')
                  || $_[0]->isa('Fey::Placeholder') },
          },
        };

    my $non_nullable_col_value_type =
        { type      => SCALAR|OBJECT,
          callbacks =>
          { 'literal, placeholder, column, or scalar' =>
            sub {    ! blessed $_[0]
                  || ( $_[0]->isa('Fey::Column') && ! $_[0]->is_alias() )
                  || ( $_[0]->isa('Fey::Literal') && ! $_[0]->isa('Fey::Literal::Null') )
                  || $_[0]->isa('Fey::Placeholder') },
          },
        };

    sub set
    {
        my $self = shift;

        if ( ! @_ || @_ % 2 )
        {
            my $count = @_;
            param_error
                "The set method expects a list of paired column objects and values but you passed $count parameters";
        }

        my @spec;
        for ( my $x = 0; $x < @_; $x += 2 )
        {
            push @spec, $column_spec;
            push @spec,
                $_[$x]->is_nullable()
                ? $nullable_col_value_type
                : $non_nullable_col_value_type;
        }

        validate_pos( @_, @spec );

        for ( my $x = 0; $x < @_; $x += 2 )
        {
            push @{ $self->{set} },
                [ $_[$x],
                  blessed $_[ $x + 1 ]
                  ? $_[ $x + 1 ]
                  : Fey::Literal->new_from_scalar( $_[ $x + 1 ] )
                ];
        }

        return $self;
    }
}

sub sql
{
    my $self = shift;

    return ( join ' ',
             $self->_update_clause(),
             $self->_set_clause(),
             $self->_where_clause(),
             $self->_order_by_clause(),
             $self->_limit_clause(),
           );
}

sub _update_clause
{
    return 'UPDATE ' . $_[0]->_tables_subclause();
}

sub _tables_subclause
{
    return ( join ', ',
             map { $_[0]->quoter()->quote_identifier( $_->name() ) }
             @{ $_[0]->{tables} }
           );
}

sub _set_clause
{
    return ( 'SET '
             . ( join ', ',
                 map {   $_->[0]->sql( $_[0]->quoter() )
                       . ' = '
                       . $_->[1]->sql( $_[0]->quoter() ) }
                 @{ $_[0]->{set} }
               )
           );
}


1;

__END__
