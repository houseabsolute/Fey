use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More tests => 33;

use Fey::SQL;


my $s = Fey::Test->mock_test_schema_with_fks();
my $dbh = Fey::Test->mock_dbh();

{
    my $q = Fey::SQL->new_select()->select();

    eval { $q->from() };
    like( $@, qr/from\(\) called with invalid parameters \(\)/,
          'from() without any parameters is an error' );
}

{
    my $q = Fey::SQL->new_select()->select();

    $q->from( $s->table('User') );

    is( $q->_from_clause($dbh), q{FROM "User"}, '_from_clause() for one table' );
}

{
    my $q = Fey::SQL->new_select()->select();

    eval { $q->from('foo') };
    like( $@, qr/from\(\) called with invalid parameters \(foo\)/,
          'from() called with one non-table argument' );
}

{
    my $q = Fey::SQL->new_select()->select();

    my $alias = $s->table('User')->alias( alias_name => 'UserA' );
    $q->from($alias);

    is( $q->_from_clause($dbh), q{FROM "User" AS "UserA"},
        '_from_clause() for one table alias' );

}

{
    my $q = Fey::SQL->new_select()->select();

    eval { $q->from( $s->table('User'), $s->table('Group') ) };
    like( $@, qr/do not share a foreign key/,
          'Cannot join two tables without a foreign key' );
}

{
    my $q = Fey::SQL->new_select()->select();

    eval { $q->from( $s->table('User'), 'foo' ) };
    like( $@, qr/\Qthe first two arguments to from() were not valid (not tables or something else joinable)/,
          'from() called with two args, one not a table' );

    eval { $q->from( 'foo', $s->table('User') ) };
    like( $@, qr/\Qthe first two arguments to from() were not valid (not tables or something else joinable)/,
          'from() called with two args, one not a table' );
}

{
    my $q = Fey::SQL->new_select()->select();

    $q->from( $s->table('User'), $s->table('UserGroup') );

    my $sql = q{FROM "User" JOIN "UserGroup" ON ("UserGroup"."user_id" = "User"."user_id")};
    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for two tables, fk not provided' );
}

{
    my $q = Fey::SQL->new_select()->select();

    $q->from( $s->table('User'), $s->table('UserGroup') );
    $q->from( $s->table('UserGroup'), $s->table('Group') );

    my $sql = q{FROM "User" JOIN "UserGroup" ON ("UserGroup"."user_id" = "User"."user_id")};
    $sql .= q{ JOIN "Group" ON ("UserGroup"."group_id" = "Group"."group_id")};

    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for two joins' );
}

{
    my $q = Fey::SQL->new_select()->select();

    $q->from( $s->table('User') );
    $q->from( $s->table('User'), $s->table('UserGroup') );

    my $sql = q{FROM "User" JOIN "UserGroup" ON ("UserGroup"."user_id" = "User"."user_id")};
    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for table alone first, then table in join' );
}

{
    my $q = Fey::SQL->new_select()->select();

    $q->from( $s->table('User'), $s->table('UserGroup') );
    $q->from( $s->table('UserGroup'), $s->table('Group') );

    # This is totally bogus, but we want to test a call to from() that
    # involves two tables we've already seen.
    my $fake_fk = Fey::FK->new( source_columns => $s->table('User')->column('user_id'),
                                target_columns => $s->table('Group')->column('group_id'),
                              );
    $q->from( $s->table('User'), $s->table('Group'), $fake_fk );

    my $sql = q{FROM "User" JOIN "Group" ON ("User"."user_id" = "Group"."group_id")};
    $sql .= q{ JOIN "UserGroup" ON ("UserGroup"."user_id" = "User"."user_id")};

    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for two joins' );
}

{
    my $q = Fey::SQL->new_select()->select();

    $q->from( $s->table('User'), $s->table('UserGroup') );
    $q->from( $s->table('Group'), $s->table('UserGroup') );

    my $sql = q{FROM "Group" JOIN "UserGroup" ON ("UserGroup"."group_id" = "Group"."group_id")};
    $sql .= q{ JOIN "User" ON ("UserGroup"."user_id" = "User"."user_id")};

    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for two joins, seen table comes second in second clause' );
}

{
    my $q = Fey::SQL->new_select()->select();

    $q->from( $s->table('User') );
    $q->from( $s->table('UserGroup') );
    $q->from( $s->table('Group') );

    my $sql = q{FROM "Group", "User", "UserGroup"};

    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for three tables with no joins' );
}

{
    my $q = Fey::SQL->new_select()->select();

    my @t = ( $s->table('User'), $s->table('UserGroup') );
    my ($fk) = $s->foreign_keys_between_tables(@t);
    $q->from( @t, $fk );

    my $sql = q{FROM "User" JOIN "UserGroup" ON ("UserGroup"."user_id" = "User"."user_id")};
    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for two tables with fk provided' );
}

{
    my $q = Fey::SQL->new_select()->select();

    my $fk = Fey::FK->new( source_columns => $s->table('User')->column('user_id'),
                           target_columns => $s->table('UserGroup')->column('group_id'),
                         );
    $s->add_foreign_key($fk);

    eval { $q->from( $s->table('User'), $s->table('UserGroup') ) };
    like( $@, qr/more than one foreign key/,
          'Cannot auto-join two tables with >1 foreign key' );

    $s->remove_foreign_key($fk);
}

{
    my $q = Fey::SQL->new_select()->select();

    $q->from( $s->table('User'), 'left', $s->table('UserGroup') );

    my $sql = q{FROM "User" LEFT OUTER JOIN "UserGroup"};
    $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id")};
    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for two tables with left outer join' );
}

{
    my $q = Fey::SQL->new_select()->select();

    $q->from( $s->table('User'), $s->table('UserGroup') );
    $q->from( $s->table('UserGroup'), 'left', $s->table('Group') );

    my $sql = q{FROM "User" JOIN "UserGroup" ON ("UserGroup"."user_id" = "User"."user_id")};
    $sql .= q{ LEFT OUTER JOIN "Group" ON ("UserGroup"."group_id" = "Group"."group_id")};

    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for regular join + left outer join' );
}

{
    my $q = Fey::SQL->new_select()->select();

    my @t = ( $s->table('User'), $s->table('UserGroup') );
    my ($fk) = $s->foreign_keys_between_tables(@t);

    $q->from( $t[0], 'left', $t[1], $fk );

    my $sql = q{FROM "User" LEFT OUTER JOIN "UserGroup"};
    $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id")};
    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for two tables with left outer join with explicit fk' );
}

{
    my $q = Fey::SQL->new_select()->select();

    $q->from( $s->table('User'), 'right', $s->table('UserGroup') );

    my $sql = q{FROM "User" RIGHT OUTER JOIN "UserGroup"};
    $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id")};
    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for two tables with right outer join' );
}

{
    my $q = Fey::SQL->new_select()->select();

    $q->from( $s->table('User'), 'full', $s->table('UserGroup') );

    my $sql = q{FROM "User" FULL OUTER JOIN "UserGroup"};
    $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id")};
    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for two tables with full outer join' );
}

{
    my $q = Fey::SQL->new_select()->select();

    $q->from( $s->table('User'), 'full', $s->table('UserGroup') );

    my $sql = q{FROM "User" FULL OUTER JOIN "UserGroup"};
    $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id")};
    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for two tables with full outer join' );
}

{
    my $q = Fey::SQL->new_select()->select();

    my $q2 = Fey::SQL->new_where( auto_placeholders => 0 );
    $q2->where( $s->table('User')->column('user_id'), '=', 2 );

    $q->from( $s->table('User'), 'left', $s->table('UserGroup'), $q2 );

    my $sql = q{FROM "User" LEFT OUTER JOIN "UserGroup"};
    $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id"};
    $sql .= q{ AND "User"."user_id" = 2)};

    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for outer join with where clause' );
}

{
    my $q = Fey::SQL->new_select()->select();

    my $q2 = Fey::SQL->new_where( auto_placeholders => 0 );
    $q2->where( $s->table('User')->column('user_id'), '=', 2 );

    my @t = ( $s->table('User'), $s->table('UserGroup') );
    my ($fk) = $s->foreign_keys_between_tables(@t);

    $q->from( $t[0], 'left', $t[1], $fk, $q2 );

    my $sql = q{FROM "User" LEFT OUTER JOIN "UserGroup"};
    $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id"};
    $sql .= q{ AND "User"."user_id" = 2)};

    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for outer join with where clause() and explicit fk' );
}

{
    my $q = Fey::SQL->new_select()->select();

    my $alias = $s->table('User')->alias( alias_name => 'UserA' );
    $q->from( $s->table('User'), $s->table('UserGroup') );
    $q->from( $alias, $s->table('UserGroup') );

    my $sql = q{FROM "User" JOIN "UserGroup"};
    $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id")};
    $sql .= q{ JOIN "User" AS "UserA"};
    $sql .= q{ ON ("UserGroup"."user_id" = "UserA"."user_id")};

    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for one table alias' );

}

{
    my $q = Fey::SQL->new_select()->select();

    eval { $q->from( $s->table('User')->column('user_id') ) };
    like( $@, qr/\Qfrom() called with invalid parameters/,
          'passing just a column to from()' );
}

{
    my $q = Fey::SQL->new_select()->select();

    eval { $q->from( $s->table('User'), 'foobar', $s->table('UserGroup') ) };
    like( $@, qr/invalid outer join type/,
          'invalid outer join type causes an error' );
}

{
    my $q = Fey::SQL->new_select()->select();

    eval { $q->from( 'not a table', 'left', $s->table('UserGroup') ) };
    like( $@, qr/from\(\) was called with invalid arguments/,
          'invalid outer join type causes an error' );
}

{
    my $q = Fey::SQL->new_select()->select();

    eval { $q->from( $s->table('UserGroup'), 'left', 'not a table' ) };
    like( $@, qr/from\(\) was called with invalid arguments/,
          'invalid outer join type causes an error' );
}

{
    my $q = Fey::SQL->new_select()->select();

    eval { $q->from( $s->table('User'), 'full', $s->table('UserGroup'), 'invalid' ) };
    like( $@, qr/\Qfrom() called with invalid parameters/,
          'passing invalid parameter to from() with outer join' );
}

{
    my $q = Fey::SQL->new_select()->select();
    my $subselect = Fey::SQL->new_select();
    $subselect->select( $s->table('User')->column('user_id') )->from( $s->table('User') );

    $q->from($subselect);

    my $sql = q{FROM ( SELECT "User"."user_id" FROM "User" ) AS SUBSELECT0};
    is( $q->_from_clause($dbh), $sql,
        '_from_clause() for subselect' );
}

{
    my $q = Fey::SQL->new_select()->select();
    my $table = Fey::Table->new( name => 'NewTable' );

    eval { $q->from($table) };
    like( $@, qr/\Qfrom() called with invalid parameters/,
          'cannot pass a table without a schema to from()' );
}

{
    my $q = Fey::SQL->new_select()->select();
    my $table = Fey::Table->new( name => 'NewTable' );

    eval { $q->from( $table, $s->table('User') ) };
    like( $@, qr/\Qthe first two arguments to from() were not valid (not tables or something else joinable)/,
          'cannot pass a table without a schema to from() as part of a join' );
}

{
    my $q = Fey::SQL->new_select()->select();
    my $table = Fey::Table->new( name => 'NewTable' );

    my $non_table = bless {}, 'Thingy';

    eval { $q->from( $table, $non_table ) };
    like( $@, qr/\Qthe first two arguments to from() were not valid (not tables or something else joinable)/,
          'cannot pass a table without a schema to from()' );
}
