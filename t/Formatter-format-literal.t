use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 12;

use_ok('Q::Literal');

require Q::Query::Formatter;


{
    my $f = Q::Query::Formatter->new( dbh => Q::Test->mock_dbh() );

    my $num = Q::Literal->number(1237);
    is( $f->format_literal($num), '1237', 'number formatted is 1237' );

    my $term = Q::Literal->term('1237.0');
    is( $f->format_literal($term), '1237.0', 'term formatted is 1237.0' );

    $term = Q::Literal->term( q{"Foo"::text} );
    is( $f->format_literal($term), q{"Foo"::text}, 'term formatted is "Foo"::text' );

    my $string = Q::Literal->string('Foo');
    is( $f->format_literal($string), q{'Foo'}, "string formatted is 'Foo'" );

    $string = Q::Literal->string("Weren't");
    is( $f->format_literal($string), q{'Weren''t'}, "string formatted is 'Weren''t'" );
}

{
    my $s = Q::Test->mock_test_schema();

    my $f = Q::Query::Formatter->new( dbh => $s->dbh() );

    my $now = Q::Literal->function( 'NOW' );
    is( $f->format_literal($now), q{NOW()},
        'NOW function formatted' );

    my $avg = Q::Literal->function( 'AVG',
                                     $s->table('User')->column('user_id') );

    is( $f->format_literal($avg), q{AVG("User"."user_id")},
        'AVG function formatted' );

    my $substr = Q::Literal->function( 'SUBSTR',
                                       $s->table('User')->column('user_id'),
                                       5, 2 );
    is( $f->format_literal($substr), q{SUBSTR("User"."user_id", 5, 2)},
        'SUBSTR function formatted' );

    my $ifnull = Q::Literal->function( 'IFNULL',
                                       $s->table('User')->column('user_id'),
                                       $s->table('User')->column('username'),
                                     );
    is( $f->format_literal($ifnull), q{IFNULL("User"."user_id", "User"."username")},
        'IFNULL function formatted' );

    my $concat = Q::Literal->function( 'CONCAT',
                                       $s->table('User')->column('user_id'),
                                       Q::Literal->string(' '),
                                       $s->table('User')->column('username'),
                                     );
    is( $f->format_literal($concat), q{CONCAT("User"."user_id", ' ', "User"."username")},
        'CONCAT function formatted' );

    my $ifnull2 = Q::Literal->function( 'IFNULL',
                                        $s->table('User')->column('user_id'),
                                        $concat,
                                      );
    is( $f->format_literal($ifnull2),
        q{IFNULL("User"."user_id", CONCAT("User"."user_id", ' ', "User"."username"))},
        'IFNULL(..., CONCAT) function formatted' );
}
