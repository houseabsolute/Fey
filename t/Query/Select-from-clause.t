use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More tests => 23;

use Fey::Query;


my $s = Fey::Test->mock_test_schema_with_fks();

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    eval { $q->from() };
    like( $@, qr/from\(\) called with invalid parameters \(\)/,
          'from() without any parameters is an error' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    $q->from( $s->table('User') );

    is( $q->_from_clause(), q{FROM "User"}, '_from_clause for one table' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    eval { $q->from('foo') };
    like( $@, qr/from\(\) called with invalid parameters \(foo\)/,
          'from() called with one non-table argument' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    my $alias = $s->table('User')->alias( alias_name => 'UserA' );
    $q->from($alias);

    is( $q->_from_clause(), q{FROM "User" AS "UserA"},
        '_from_clause for one table alias' );

}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    eval { $q->from( $s->table('User'), $s->table('Group') ) };
    like( $@, qr/do not share a foreign key/,
          'Cannot join two tables without a foreign key' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    eval { $q->from( $s->table('User'), 'foo' ) };
    like( $@, qr/invalid first two arguments/,
          'from() called with two args, one not a table' );

    eval { $q->from( 'foo', $s->table('User') ) };
    like( $@, qr/invalid first two arguments/,
          'from() called with two args, one not a table' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    $q->from( $s->table('User'), $s->table('UserGroup') );

    my $sql = q{FROM "User" JOIN "UserGroup" ON "User"."user_id" = "UserGroup"."user_id"};
    is( $q->_from_clause(), $sql,
        '_from_clause for two tables, fk not provided' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    my @t = ( $s->table('User'), $s->table('UserGroup') );
    my ($fk) = $s->foreign_keys_between_tables(@t);
    $q->from( @t, $fk );

    my $sql = q{FROM "User" JOIN "UserGroup" ON "User"."user_id" = "UserGroup"."user_id"};
    is( $q->_from_clause(), $sql,
        '_from_clause for two tables with fk provided' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    my $fk = Fey::FK->new( source => $s->table('User')->column('user_id'),
                         target => $s->table('UserGroup')->column('group_id'),
                       );
    $s->add_foreign_key($fk);

    eval { $q->from( $s->table('User'), $s->table('UserGroup') ) };
    like( $@, qr/more than one foreign key/,
          'Cannot auto-join two tables with >1 foreign key' );

    $s->remove_foreign_key($fk);
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    $q->from( $s->table('User'), 'left', $s->table('UserGroup') );

    my $sql = q{FROM "User" LEFT OUTER JOIN "UserGroup"};
    $sql .= q{ ON "User"."user_id" = "UserGroup"."user_id"};
    is( $q->_from_clause(), $sql,
        '_from_clause for two tables with left outer join' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    my @t = ( $s->table('User'), $s->table('UserGroup') );
    my ($fk) = $s->foreign_keys_between_tables(@t);

    $q->from( $t[0], 'left', $t[1], $fk );

    my $sql = q{FROM "User" LEFT OUTER JOIN "UserGroup"};
    $sql .= q{ ON "User"."user_id" = "UserGroup"."user_id"};
    is( $q->_from_clause(), $sql,
        '_from_clause for two tables with left outer join with explicit fk' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    $q->from( $s->table('User'), 'right', $s->table('UserGroup') );

    my $sql = q{FROM "User" RIGHT OUTER JOIN "UserGroup"};
    $sql .= q{ ON "User"."user_id" = "UserGroup"."user_id"};
    is( $q->_from_clause(), $sql,
        '_from_clause for two tables with right outer join' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    $q->from( $s->table('User'), 'full', $s->table('UserGroup') );

    my $sql = q{FROM "User" FULL OUTER JOIN "UserGroup"};
    $sql .= q{ ON "User"."user_id" = "UserGroup"."user_id"};
    is( $q->_from_clause(), $sql,
        '_from_clause for two tables with full outer join' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    $q->from( $s->table('User'), 'full', $s->table('UserGroup') );

    my $sql = q{FROM "User" FULL OUTER JOIN "UserGroup"};
    $sql .= q{ ON "User"."user_id" = "UserGroup"."user_id"};
    is( $q->_from_clause(), $sql,
        '_from_clause for two tables with full outer join' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    my $q2 = Fey::Query->new( dbh => $s->dbh() );
    $q2->where( $s->table('User')->column('user_id'), '=', 2 );

    $q->from( $s->table('User'), 'left', $s->table('UserGroup'), $q2 );

    my $sql = q{FROM "User" LEFT OUTER JOIN "UserGroup"};
    $sql .= q{ ON "User"."user_id" = "UserGroup"."user_id"};
    $sql .= q{ WHERE "User"."user_id" = 2};

    is( $q->_from_clause(), $sql,
        '_from_clause for outer join with where clause' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    my $q2 = Fey::Query->new( dbh => $s->dbh() );
    $q2->where( $s->table('User')->column('user_id'), '=', 2 );

    my @t = ( $s->table('User'), $s->table('UserGroup') );
    my ($fk) = $s->foreign_keys_between_tables(@t);

    $q->from( $t[0], 'left', $t[1], $fk, $q2 );

    my $sql = q{FROM "User" LEFT OUTER JOIN "UserGroup"};
    $sql .= q{ ON "User"."user_id" = "UserGroup"."user_id"};
    $sql .= q{ WHERE "User"."user_id" = 2};

    is( $q->_from_clause(), $sql,
        '_from_clause for outer join with where clause and explicit fk' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    eval { $q->from( $s->table('User')->column('user_id') ) };
    like( $@, qr/\Qfrom() called with invalid parameters/,
          'passing just a column to from()' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    eval { $q->from( $s->table('User'), 'foobar', $s->table('UserGroup') ) };
    like( $@, qr/invalid outer join type/,
          'invalid outer join type causes an error' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    eval { $q->from( 'not a table', 'left', $s->table('UserGroup') ) };
    like( $@, qr/from\(\) was called with invalid arguments/,
          'invalid outer join type causes an error' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    eval { $q->from( $s->table('UserGroup'), 'left', 'not a table' ) };
    like( $@, qr/from\(\) was called with invalid arguments/,
          'invalid outer join type causes an error' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();

    eval { $q->from( $s->table('User'), 'full', $s->table('UserGroup'), 'invalid' ) };
    like( $@, qr/\Qfrom() called with invalid parameters/,
          'passing invalid parameter to from() with outer join' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->select();
    my $subselect = Fey::Query->new( dbh => $s->dbh() );
    $subselect->select( $s->table('User')->column('user_id') )->from( $s->table('User') );

    $q->from($subselect);

    my $sql = q{FROM ( SELECT "User"."user_id" FROM "User" ) AS SUBSELECT0};
    is( $q->_from_clause(), $sql,
        '_from_clause for subselect' );
}
