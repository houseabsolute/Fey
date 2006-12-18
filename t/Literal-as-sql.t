use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 28;

use Q::Literal;
use Q::Query::Formatter;


{
    my $f = Q::Query::Formatter->new( dbh => Q::Test->mock_dbh() );

    my $num = Q::Literal->number(1237);
    is( $num->sql_with_alias($f), '1237', 'number sql_with_alias is 1237' );
    is( $num->sql_or_alias($f), '1237', 'number sql_or_alias is 1237' );
    is( $num->sql($f), '1237',
        'number sql is 1237' );

    my $term = Q::Literal->term('1237.0');
    is( $term->sql_with_alias($f), '1237.0', 'term sql_with_alias is 1237.0' );
    is( $term->sql_or_alias($f), '1237.0',
        'term sql_or_alias is 1237.0' );
    is( $term->sql($f), '1237.0',
        'term sql is 1237.0' );

    $term = Q::Literal->term( q{"Foo"::text} );
    is( $term->sql_or_alias($f),
        q{"Foo"::text}, 'term sql_with_alias is "Foo"::text' );
    is( $term->sql_or_alias($f),
        q{"Foo"::text}, 'term sql_or_alias is "Foo"::text' );
    is( $term->sql($f),
        q{"Foo"::text}, 'term sql is "Foo"::text' );

    my $string = Q::Literal->string('Foo');
    is( $string->sql_with_alias($f), q{'Foo'}, "string sql_with_alias is 'Foo'" );
    is( $string->sql_or_alias($f), q{'Foo'}, "string sql_or_alias is 'Foo'" );
    is( $string->sql($f), q{'Foo'}, "string sql is 'Foo'" );

    $string = Q::Literal->string("Weren't");
    is( $string->sql_or_alias($f),
        q{'Weren''t'}, "string formatted is 'Weren''t'" );

    my $null = Q::Literal->null();
    is( $null->sql_with_alias($f), 'NULL', 'null sql_with_alias' );
    is( $null->sql_or_alias($f), 'NULL', 'null sql_or_alias' );
    is( $null->sql($f), 'NULL', 'null sql' );
}

{
    my $s = Q::Test->mock_test_schema();

    my $f = Q::Query::Formatter->new( dbh => $s->dbh() );

    my $now = Q::Literal->function( 'NOW' );
    is( $now->sql_with_alias($f), q{NOW() AS FUNCTION0},
        'NOW function sql_with_alias' );
    is( $now->sql_or_alias($f), q{"FUNCTION0"},
        'NOW function sql_or_alias - with alias' );
    is( $now->sql($f), 'NOW()',
        'NOW function sql - with alias' );

    my $now2 = Q::Literal->function( 'NOW' );
    is( $now2->sql_or_alias($f), q{NOW()},
        'NOW function sql_or_alias - no alias' );
    is( $now2->sql($f), q{NOW()},
        'NOW function sql - no alias' );

    my $avg = Q::Literal->function( 'AVG',
                                     $s->table('User')->column('user_id') );

    is( $avg->sql_or_alias($f), q{AVG("User"."user_id")},
        'AVG function formatted' );

    my $substr = Q::Literal->function( 'SUBSTR',
                                       $s->table('User')->column('user_id'),
                                       5, 2 );
    is( $substr->sql_or_alias($f), q{SUBSTR("User"."user_id", 5, 2)},
        'SUBSTR function formatted' );

    my $ifnull = Q::Literal->function( 'IFNULL',
                                       $s->table('User')->column('user_id'),
                                       $s->table('User')->column('username'),
                                     );
    is( $ifnull->sql_or_alias($f), q{IFNULL("User"."user_id", "User"."username")},
        'IFNULL function formatted' );

    my $concat = Q::Literal->function( 'CONCAT',
                                       $s->table('User')->column('user_id'),
                                       Q::Literal->string(' '),
                                       $s->table('User')->column('username'),
                                     );
    is( $concat->sql_or_alias($f),
        q{CONCAT("User"."user_id", ' ', "User"."username")},
        'CONCAT function formatted' );

    my $ifnull2 = Q::Literal->function( 'IFNULL',
                                        $s->table('User')->column('user_id'),
                                        $concat,
                                      );
    is( $ifnull2->sql_or_alias($f),
        q{IFNULL("User"."user_id", CONCAT("User"."user_id", ' ', "User"."username"))},
        'IFNULL(..., CONCAT) function formatted' );

    my $avg2 =
        Q::Literal->function
            ( 'AVG',
              $s->table('User')->column('user_id')->alias( alias_name => 'uid' ) );
    is( $avg2->sql_or_alias($f), q{AVG("uid")},
        'AVG() with column alias as argument' );
}

{
    my $f = Q::Query::Formatter->new( dbh => Q::Test->mock_dbh() );

    my $now = Q::Literal->function( 'NOW' );
    $now->_make_alias();

    like( $now->sql_or_alias($f), qr/FUNCTION\d+/,
        'NOW function formatted for compare when it has an alias returns alias' );
}

