use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 7;


use_ok( 'Q::Column' );

{
    eval { my $s = Q::Column->new() };
    like( $@, qr/Mandatory parameters .+ missing/,
          'name, generic_type and type are required params' );
}

{
    my $c = Q::Column->new( name         => 'Test',
                            type         => 'foobar',
                            generic_type => 'text',
                          );

    is( $c->name(), 'Test', 'column name is Test' );
    is( $c->type(), 'foobar', 'column type is foobar' );
    is( $c->generic_type(), 'text', 'column generic type is text' );
    ok( ! $c->is_nullable(), 'column defaults to not nullable' );
}

{
    my $c = Q::Column->new( name         => 'Test',
                            type         => 'foobar',
                            generic_type => 'text',
                            is_nullable  => 1,
                          );

    ok( $c->is_nullable(), 'column is nullable' );
}
