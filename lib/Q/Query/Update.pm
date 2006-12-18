package Q::Query::Update;

use strict;
use warnings;

use base 'Q::Query';

use Q::Exceptions qw( param_error );
use Q::Validate
    qw( validate_pos
        OBJECT
        NULLABLE_COL_VALUE_TYPE
        NON_NULLABLE_COL_VALUE_TYPE
      );

use Scalar::Util qw( blessed );


{
    my $spec = { type => OBJECT,
                 callbacks =>
                 { 'is a (non-alias) table' =>
                   sub {    $_[0]->isa('Q::Table')
                         && ! $_[0]->is_alias() },
                 },
               };

    sub update
    {
        my $self     = shift;
        my (@tables) = validate_pos( @_, ($spec) x @_ );

        $self->{tables} = \@tables;

        return $self;
    }
}

{
    my $column_spec = { type => OBJECT,
                        callbacks =>
                        { 'is a (non-alias) column' =>
                          sub {    $_[0]->isa('Q::Column')
                                && $_[0]->table()
                                && ! $_[0]->isa_alias() },
                        },
                      };

    sub set
    {
        my $self = shift;

        unless ( @_ && ! @_ % 2 )
        {
            param_error
                'The set method expects a list of paired column objects and values';
        }

        my @spec;
        for ( my $x = 0; $x < @_; $x += 2 )
        {
            push @spec, $column_spec;
            push @spec,
                $_[$x]->is_nullable()
                ? NULLABLE_COL_VALUE_TYPE
                : NON_NULLABLE_COL_VALUE_TYPE;
        }

        my @pairs = validate_pos( @_, @spec );

        push @{ $self->{set} }, @pairs;

        return $self;
    }
}

sub sql
{
    my $self = shift;

    return ( join ' ',
             $self->_update_clause(),
             $self->_set_clause(),
           );
}

sub _update_clause
{
    return 'UPDATE ' . $_[0]->_tables_subclause();
}

sub _tables_subclause
{
    return ( join ', ',
             map { $_[0]->formatter()->quote_indentifier( $_ ) }
             @{ $_[0]->{tables} }
           );
}

sub _set_clause
{
    my $self = shift;

    my $sql = '';
    for ( my $x = 0; $x < @{ $self->{set} }; $x += 2 )
    {
        $sql .= $self->{set}[$x]->sql();
        $sql .= ' = ';
        $sql .= $self->{set}[$x + 1]->sql();
    }

    return $sql;
}



1;

__END__
