use strict;
use warnings;

use Test::More tests => 6;

use Q::Validate qw( validate :types );


{
    my @p = ( foo => -1 );
    eval { validate( @p, { foo => POS_OR_ZERO_INTEGER_TYPE } ) };
    like( $@, qr/is a positive or zero integer/,
          'test POS_OR_ZERO_INTEGER_TYPE with -1' );

    @p = ( foo => 0 );
    eval { validate( @p, { foo => POS_OR_ZERO_INTEGER_TYPE } ) };
    is( $@, '', 'test POS_OR_ZERO_INTEGER_TYPE with 0' );

    @p = ( foo => 42 );
    eval { validate( @p, { foo => POS_OR_ZERO_INTEGER_TYPE } ) };
    is( $@, '', 'test POS_OR_ZERO_INTEGER_TYPE with 42' );
}

{
    my @p = ( foo => -1 );
    eval { validate( @p, { foo => POS_INTEGER_TYPE } ) };
    like( $@, qr/is a positive integer/,
          'test POS_OR_ZERO_INTEGER_TYPE with -1' );

    @p = ( foo => 0 );
    eval { validate( @p, { foo => POS_INTEGER_TYPE } ) };
    like( $@, qr/is a positive integer/,
          'test POS_OR_ZERO_INTEGER_TYPE with 0' );

    @p = ( foo => 42 );
    eval { validate( @p, { foo => POS_INTEGER_TYPE } ) };
    is( $@, '', 'test POS_INTEGER_TYPE with 42' );
}
