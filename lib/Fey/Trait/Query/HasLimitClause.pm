package Fey::Trait::SQL::HasLimitClause;

use strict;
use warnings;

use Class::Trait 'base';

use Fey::Validate
    qw( validate_pos
        POS_INTEGER_TYPE
        POS_OR_ZERO_INTEGER_TYPE
      );

use Scalar::Util qw( blessed );


{
    my @spec = ( POS_INTEGER_TYPE, POS_OR_ZERO_INTEGER_TYPE( optional => 1 ) );
    sub limit
    {
        my $self = shift;
        my @limit = validate_pos( @_, @spec );

        $self->{limit}{number} = $limit[0];
        $self->{limit}{offset} = $limit[1];
    }
}

sub _limit_clause
{
    my $self = shift;

    return unless $self->{limit}{number};

    my $sql = 'LIMIT ' . $self->{limit}{number};
    $sql .= ' OFFSET ' . $self->{limit}{offset}
        if $self->{limit}{offset};

    return $sql;
}


1;

__END__
