use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More tests => 30;

use Fey::SQL;

my $s = Fey::Test->mock_test_schema_with_fks();
my $dbh = Fey::Test->mock_dbh();

my $subselect_id = 0;

for my $keyword ( qw( UNION INTERSECT EXCEPT ) )
{
    my $new_method = "new_" . lc $keyword;
    my $method = lc $keyword;

    {
        my $q = Fey::SQL->$new_method();

        eval { $q->$method() };
        like( $@, qr/0 parameters were passed .+ but 2 were expected/,
              "$method() without any parameters is an error" );

        eval { $q->$method( Fey::SQL->new_select ) };
        like( $@, qr/1 parameter .+ but 2 were expected/,
              "$method() with only one parameter is an error" );

        local $TODO = "MooseX::Params::Validate gets the method name wrong"
            if $keyword ne 'EXCEPT';
        eval { $q->$method() };
        like( $@, qr/0 parameters were passed to .+::$method/,
              "$method() error message has correct method name" );
    }

    {
        my $q = Fey::SQL->$new_method();

        eval { $q->$method( 1, 2 ) };
        like( $@,
              qr/did not pass the 'checking type constraint for Fey\.Type\.SetOperationArg'/,
              "$method() with a non-Select parameter is an error",
            );
    }

    {
        my $q = Fey::SQL->$new_method();

        my $sel1 = Fey::SQL->new_select->select(1)->from( $s->table('User') );
        my $sel2 = Fey::SQL->new_select->select(2)->from( $s->table('User') );

        $q->$method( $sel1, $sel2 );

        my $sql = qq{(SELECT 1 FROM "User") $keyword (SELECT 2 FROM "User")};
        is( $q->sql($dbh), $sql, "$method() with two tables" );

        my $sel3 = Fey::SQL->new_select->select(1)->from($q);
        $sql = qq{SELECT 1 FROM ( $sql ) AS SUBSELECT} . $subselect_id++;
        is( $sel3->sql($dbh), $sql, "$method() as subselect" );
    }

    {
        my $q = Fey::SQL->$new_method()->all();

        my $sel1 = Fey::SQL->new_select->select(1)->from( $s->table('User') );
        my $sel2 = Fey::SQL->new_select->select(2)->from( $s->table('User') );

        $q->$method( $sel1, $sel2 );

        my $sql = qq{(SELECT 1 FROM "User") };
        $sql   .= qq{$keyword ALL (SELECT 2 FROM "User")};
        is( $q->sql($dbh), $sql, "$method()->all() with two tables" );

        my $sel3 = Fey::SQL->new_select->select(3)->from( $s->table('User') );

        eval { $q->$method($sel3) };
        is $@, '', 'no error from adding a single select when 2 are present';
    }

    {
        my $q = Fey::SQL->$new_method();

        my $user = $s->table('User');

        my $sel1 = Fey::SQL->new_select();
        $sel1->select( $user->column('user_id') )->from($user);

        my $sel2 = Fey::SQL->new_select();
        $sel2->select( $user->column('user_id') )->from($user);

        $q->$method( $sel1, $sel2 )->order_by( $user->column('user_id') );

        my $sql = q{(SELECT "User"."user_id" FROM "User")};
        $sql = "$sql $keyword $sql";
        $sql .= q{ ORDER BY "User"."user_id"};

        is( $q->sql($dbh), $sql, "$method() with order by" );
    }

    {
        my $q = Fey::SQL->$new_method();

        my $sel1 = Fey::SQL->new_select->select(1)->from( $s->table('User') );
        my $sel2 = Fey::SQL->new_select->select(2)->from( $s->table('User') );
        my $sel3 = Fey::SQL->new_select->select(3)->from( $s->table('User') );

        $q->$method( $sel1, Fey::SQL->$new_method->$method( $sel2, $sel3 ) );

        my $from = qq{FROM "User"};
        my $sql = qq{(SELECT 1 $from) $keyword };
        $sql .=   qq{((SELECT 2 $from) $keyword (SELECT 3 $from))};
        is( $q->sql($dbh), $sql, "$method() with sub-$method" );
    }
}
