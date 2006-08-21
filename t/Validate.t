use strict;
use warnings;

use Test::More tests => 10;

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

{
    eval { my $t = SCALAR_TYPE( default => 0 => 1 ) };
    like( $@, qr/Invalid additional args for SCALAR_TYPE/,
          'check that calling type sub with odd number of args fails' );
}

{
    require Q::Table;
    my $table = Q::Table->new( name => 'Test' );

    my @p = ( table => $table );
    eval { validate( @p, { table => TABLE_OR_NAME_TYPE } ) };
    is( $@, '', 'TABLE_OR_NAME_TYPE succeeds with table object' );

    @p = ( table => 'Test' );
    eval { validate( @p, { table => TABLE_OR_NAME_TYPE } ) };
    is( $@, '', 'TABLE_OR_NAME_TYPE succeeds with defined scalar' );

    @p = ( table => bless { foo => 1 }, 'Foo' );
    eval { validate( @p, { table => TABLE_OR_NAME_TYPE } ) };
    like( $@, qr/is a Q::Table object or name/,
          'TABLE_OR_NAME_TYPE failed with Foo object' );
}
