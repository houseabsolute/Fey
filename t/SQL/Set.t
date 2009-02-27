use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More 'no_plan';

use Fey::SQL;

my $s = Fey::Test->mock_test_schema_with_fks();
my $dbh = Fey::Test->mock_dbh();


{
    my $q = Fey::SQL->new_union();

    eval { $q->union() };
    like( $@, qr/0 parameters were passed to .+union but 2 were expected/,
          'union() without any parameters is an error' );

    eval { $q->union( Fey::SQL->new_select ) };
    like( $@, qr/1 parameter .+but 2 were expected/,
          'union() with only one parameter is an error' );
}

{
    my $q = Fey::SQL->new_union();

    eval { $q->union( 1, 2 ) };
    like( $@,
          qr/did not pass the 'checking type constraint for Fey::SQL::Select'/,
          'union() with a non-Select parameter is an error',
        );
}

{
    my $q = Fey::SQL->new_union();

    my $sel1 = Fey::SQL->new_select->select(1)->from( $s->table('User') );
    my $sel2 = Fey::SQL->new_select->select(2)->from( $s->table('User') );

    $q->union( $sel1, $sel2 );

    my $sql = q{(SELECT 1 FROM "User") UNION (SELECT 2 FROM "User")};
    is( $q->sql($dbh), $sql, 'union() with two tables' );

    my $sel3 = Fey::SQL->new_select->select(1)->from($q);
    $sql = qq{SELECT 1 FROM ( $sql ) AS SUBSELECT0};
    is( $sel3->sql($dbh), $sql, 'union() as subselect' );
}

{
    my $q = Fey::SQL->new_union();

    my $user = $s->table('User');

    my $sel1 = Fey::SQL->new_select();
    $sel1->select( $user->column('user_id') )->from( $user );

    my $sel2 = Fey::SQL->new_select();
    $sel2->select( $user->column('user_id') )->from( $user );
                
    $q->union( $sel1, $sel2 )->order_by( $user->column('user_id') );

    my $sql = q{(SELECT "User"."user_id" FROM "User")};
    $sql = "$sql UNION $sql";
    $sql .= q{ ORDER BY "User"."user_id"};

    is( $q->sql($dbh), $sql, 'union() with order by' );
}
