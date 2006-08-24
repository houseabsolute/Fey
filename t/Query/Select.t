use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 4;

use Q::Query;

my $s = Q::Test->mock_test_schema();

{
    my $q = Q::Query->new( dbh => $s->dbh() );

    $q->select( $s->table('User') );

    isa_ok( $q, 'Q::Query::Select' );

    my $sql = q{SELECT "User"."email", "User"."user_id", "User"."username"};
    is( $q->_start_clause(), $sql,
        '_start_clause with one table'
      );

    $q->select( $s->table('User') );
    is( $q->_start_clause(), $sql,
        '_start_clause even when same table is added twice'
      );

    $q->select( $s->table('User')->column('user_id') );
    is( $q->_start_clause(), $sql,
        '_start_clause even when table and column from that table are both added'
      );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() );

    $q->select( $s->table('User') );

    my $user_alias = $s->table('User')->alias( alias_name => 'UserA' );
    $q->select($user_alias);

    my $sql = q{SELECT "User"."email", "User"."user_id", "User"."username"};
    $sql .= q{, "UserA"."email", "UserA"."user_id", "UserA"."username"};

    is( $q->_start_clause(), $sql,
        '_start_clause with table alias'
      );

    $q->select($user_alias);
    is( $q->_start_clause(), $sql,
        '_start_clause with table alias even when same alias is added twice'
      );

    $q->select( $user_alias->column('user_id') );
    is( $q->_start_clause(), $sql,
        '_start_clause even when alias and column from that alias are both added'
      );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() );

    $q->select( $s->table('User')->column('user_id') );
    $q->select( $s->table('User') );

    my $sql = q{SELECT "User"."email", "User"."user_id", "User"."username"};
    is( $q->_start_clause(), $sql,
        '_start_clause when first adding column and then table for that column'
      );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() );

    $q->select( $s->table('User')->column('user_id') );
    $q->select( $s->table('User')->column('user_id')
                                 ->alias( alias_name => 'new_user_id' ) );

    my $sql = q{SELECT "User"."user_id" AS "new_user_id", "User"."user_id"};
    is( $q->_start_clause(), $sql,
        '_start_clause with column and alias for that column'
      );
}
