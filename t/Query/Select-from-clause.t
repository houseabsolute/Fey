use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 15;

use Q::Query;


my $s = Q::Test->mock_test_schema_with_fks();

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    eval { $q->from() };
    like( $@, qr/from\(\) called with invalid parameters \(\)/,
          'from() without any parameters is an error' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->from( $s->table('User') );

    is( $q->_from_clause(), q{FROM "User"}, '_from_clause for one table' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    eval { $q->from('foo') };
    like( $@, qr/A single argument to from\(\) must be a table/,
          'from() called with one non-table argument' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    my $alias = $s->table('User')->alias( alias_name => 'UserA' );
    $q->from($alias);

    is( $q->_from_clause(), q{FROM "User" AS "UserA"},
        '_from_clause for one table alias' );

}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    eval { $q->from( $s->table('User'), $s->table('Group') ) };
    like( $@, qr/do not share a foreign key/,
          'Cannot join two tables without a foreign key' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    eval { $q->from( $s->table('User'), 'foo' ) };
    like( $@, qr/invalid first two arguments/,
          'from() called with two args, one not a table' );

    eval { $q->from( 'foo', $s->table('User') ) };
    like( $@, qr/invalid first two arguments/,
          'from() called with two args, one not a table' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->from( $s->table('User'), $s->table('UserGroup') );

    my $sql = q{FROM "User" JOIN "UserGroup" ON "User"."user_id" = "UserGroup"."user_id"};
    is( $q->_from_clause(), $sql,
        '_from_clause for two tables, fk not provided' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    my @t = ( $s->table('User'), $s->table('UserGroup') );
    my ($fk) = $s->foreign_keys_between_tables(@t);
    $q->from( @t, $fk );

    my $sql = q{FROM "User" JOIN "UserGroup" ON "User"."user_id" = "UserGroup"."user_id"};
    is( $q->_from_clause(), $sql,
        '_from_clause for two tables with fk provided' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    my $fk = Q::FK->new( source => $s->table('User')->column('user_id'),
                         target => $s->table('UserGroup')->column('group_id'),
                       );
    $s->add_foreign_key($fk);

    eval { $q->from( $s->table('User'), $s->table('UserGroup') ) };
    like( $@, qr/more than one foreign key/,
          'Cannot auto-join two tables with >1 foreign key' );

    $s->remove_foreign_key($fk);
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->from( $s->table('User'), 'left', $s->table('UserGroup') );

    my $sql = q{FROM "User" LEFT OUTER JOIN "UserGroup"};
    $sql .= q{ ON "User"."user_id" = "UserGroup"."user_id"};
    is( $q->_from_clause(), $sql,
        '_from_clause for two tables with left outer join' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    my @t = ( $s->table('User'), $s->table('UserGroup') );
    my ($fk) = $s->foreign_keys_between_tables(@t);

    $q->from( $t[0], 'left', $t[1], $fk );

    my $sql = q{FROM "User" LEFT OUTER JOIN "UserGroup"};
    $sql .= q{ ON "User"."user_id" = "UserGroup"."user_id"};
    is( $q->_from_clause(), $sql,
        '_from_clause for two tables with left outer join with explicit fk' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->from( $s->table('User'), 'right', $s->table('UserGroup') );

    my $sql = q{FROM "User" RIGHT OUTER JOIN "UserGroup"};
    $sql .= q{ ON "User"."user_id" = "UserGroup"."user_id"};
    is( $q->_from_clause(), $sql,
        '_from_clause for two tables with right outer join' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->from( $s->table('User'), 'full', $s->table('UserGroup') );

    my $sql = q{FROM "User" FULL OUTER JOIN "UserGroup"};
    $sql .= q{ ON "User"."user_id" = "UserGroup"."user_id"};
    is( $q->_from_clause(), $sql,
        '_from_clause for two tables with full outer join' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->from( $s->table('User'), 'full', $s->table('UserGroup') );

    my $sql = q{FROM "User" FULL OUTER JOIN "UserGroup"};
    $sql .= q{ ON "User"."user_id" = "UserGroup"."user_id"};
    is( $q->_from_clause(), $sql,
        '_from_clause for two tables with full outer join' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    eval { $q->from( $s->table('User'), 'foobar', $s->table('UserGroup') ) };
    like( $@, qr/invalid outer join type/,
          'invalid outer join type causes an error' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    eval { $q->from( 'not a table', 'left', $s->table('UserGroup') ) };
    like( $@, qr/from\(\) was called with invalid arguments/,
          'invalid outer join type causes an error' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    eval { $q->from( $s->table('UserGroup'), 'left', 'not a table' ) };
    like( $@, qr/from\(\) was called with invalid arguments/,
          'invalid outer join type causes an error' );
}
