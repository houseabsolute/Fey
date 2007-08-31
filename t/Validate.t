use strict;
use warnings;

use Test::More tests => 12;

use Fey::Table;
use Fey::Validate qw( validate :types );


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
    my $table = Fey::Table->new( name => 'Test' );

    my @p = ( table => $table );
    eval { validate( @p, { table => TABLE_OR_NAME_TYPE } ) };
    is( $@, '', 'TABLE_OR_NAME_TYPE succeeds with table object' );

    @p = ( table => 'Test' );
    eval { validate( @p, { table => TABLE_OR_NAME_TYPE } ) };
    is( $@, '', 'TABLE_OR_NAME_TYPE succeeds with defined scalar' );

    @p = ( table => bless { foo => 1 }, 'Foo' );
    eval { validate( @p, { table => TABLE_OR_NAME_TYPE } ) };
    like( $@, qr/is a Fey::Table object or name/,
          'TABLE_OR_NAME_TYPE failed with Foo object' );
}

{
    my @p = ( object => NoName->new() );
    eval { validate( @p, { object => NAMED_OBJECT_TYPE } ) };
    like( $@, qr/does not have the method: 'name'/,
          'NAMED_OBJECT_TYPE failed with NoName object' );

    @p = ( object => Name->new() );
    eval { validate( @p, { object => NAMED_OBJECT_TYPE } ) };
    is( $@, '',
        'test NAMED_OBJECT_TYPE with a Name object' );
}

package NoName;

sub new { return bless {}, shift }

package Name;

sub new { return bless {}, shift }

sub name { 'Bob' }
