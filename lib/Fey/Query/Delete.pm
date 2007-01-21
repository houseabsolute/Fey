package Fey::Query::Delete;

use strict;
use warnings;

use base 'Fey::Query';

use Class::Trait ( 'Fey::Trait::Query::HasWhereClause',
                   'Fey::Trait::Query::HasOrderByClause',
                   'Fey::Trait::Query::HasLimitClause',
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
