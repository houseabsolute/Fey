use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 13;

use Q::Literal;
use Q::Query::Formatter;


{
    my $f = Q::Query::Formatter->new( dbh => Q::Test->mock_dbh() );

    my $num = Q::Literal->number(1237);
    is( $num->sql_for_compare($f), '1237', 'number formatted is 1237' );

    my $term = Q::Literal->term('1237.0');
    is( $term->sql_for_compare($f), '1237.0', 'term formatted is 1237.0' );

    $term = Q::Literal->term( q{"Foo"::text} );
    is( $term->sql_for_compare($f),
        q{"Foo"::text}, 'term formatted is "Foo"::text' );

    my $string = Q::Literal->string('Foo');
    is( $string->sql_for_compare($f), q{'Foo'}, "string formatted is 'Foo'" );

    $string = Q::Literal->string("Weren't");
    is( $string->sql_for_compare($f),
        q{'Weren''t'}, "string formatted is 'Weren''t'" );
}

{
    my $s = Q::Test->mock_test_schema();

    my $f = Q::Query::Formatter->new( dbh => $s->dbh() );

    my $now = Q::Literal->function( 'NOW' );
    is( $now->sql_for_compare($f), q{NOW()},
        'NOW function formatted' );

    my $avg = Q::Literal->function( 'AVG',
                                     $s->table('User')->column('user_id') );

    is( $avg->sql_for_compare($f), q{AVG("User"."user_id")},
        'AVG function formatted' );

    my $substr = Q::Literal->function( 'SUBSTR',
                                       $s->table('User')->column('user_id'),
                                       5, 2 );
    is( $substr->sql_for_compare($f), q{SUBSTR("User"."user_id", 5, 2)},
        'SUBSTR function formatted' );

    my $ifnull = Q::Literal->function( 'IFNULL',
                                       $s->table('User')->column('user_id'),
                                       $s->table('User')->column('username'),
                                     );
    is( $ifnull->sql_for_compare($f), q{IFNULL("User"."user_id", "User"."username")},
        'IFNULL function formatted' );

    my $concat = Q::Literal->function( 'CONCAT',
                                       $s->table('User')->column('user_id'),
                                       Q::Literal->string(' '),
                                       $s->table('User')->column('username'),
                                     );
    is( $concat->sql_for_compare($f),
        q{CONCAT("User"."user_id", ' ', "User"."username")},
        'CONCAT function formatted' );

    my $ifnull2 = Q::Literal->function( 'IFNULL',
                                        $s->table('User')->column('user_id'),
                                        $concat,
                                      );
    is( $ifnull2->sql_for_compare($f),
        q{IFNULL("User"."user_id", CONCAT("User"."user_id", ' ', "User"."username"))},
        'IFNULL(..., CONCAT) function formatted' );

    my $avg2 =
        Q::Literal->function
            ( 'AVG',
              $s->table('User')->column('user_id')->alias( alias_name => 'uid' ) );
    is( $avg2->sql_for_compare($f), q{AVG("uid")},
        'AVG() with column alias as argument' );
}

{
    my $f = Q::Query::Formatter->new( dbh => Q::Test->mock_dbh() );

    my $now = Q::Literal->function( 'NOW' );
    $now->_make_alias();

    like( $now->sql_for_compare($f), qr/FUNCTION\d+/,
        'NOW function formatted for compare when it has an alias returns alias' );
}

