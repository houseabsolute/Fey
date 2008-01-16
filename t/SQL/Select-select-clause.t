use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More tests => 13;

use Fey::SQL;


my $s = Fey::Test->mock_test_schema();
my $dbh = Fey::Test->mock_dbh();

{
    my $q = Fey::SQL->new_select();

    $q->select( $s->table('User') );

    isa_ok( $q, 'Fey::SQL::Select' );

    my $sql = q{SELECT "User"."email", "User"."user_id", "User"."username"};
    is( $q->_select_clause($dbh), $sql,
        '_select_clause with one table'
      );

    $q->select( $s->table('User') );
    is( $q->_select_clause($dbh), $sql,
        '_select_clause even when same table is added twice'
      );

    $q->select( $s->table('User')->column('user_id') );
    is( $q->_select_clause($dbh), $sql,
        '_select_clause even when table and column from that table are both added'
      );
}

{
    my $q = Fey::SQL->new_select();

    $q->select( $s->table('User') );

    my $user_alias = $s->table('User')->alias( alias_name => 'UserA' );
    $q->select($user_alias);

    my $sql = q{SELECT "User"."email", "User"."user_id", "User"."username"};
    $sql .= q{, "UserA"."email", "UserA"."user_id", "UserA"."username"};

    is( $q->_select_clause($dbh), $sql,
        '_select_clause with table alias'
      );

    $q->select($user_alias);
    is( $q->_select_clause($dbh), $sql,
        '_select_clause with table alias even when same alias is added twice'
      );

    $q->select( $user_alias->column('user_id') );
    is( $q->_select_clause($dbh), $sql,
        '_select_clause even when alias and column from that alias are both added'
      );
}

{
    my $q = Fey::SQL->new_select();

    $q->select( $s->table('User')->column('user_id') );
    $q->select( $s->table('User') );

    my $sql = q{SELECT "User"."email", "User"."user_id", "User"."username"};
    is( $q->_select_clause($dbh), $sql,
        '_select_clause when first adding column and then table for that column'
      );
}

{
    my $q = Fey::SQL->new_select();

    $q->select( $s->table('User')->column('user_id') );
    $q->select( $s->table('User')->column('user_id')
                                 ->alias( alias_name => 'new_user_id' ) );

    my $sql = q{SELECT "User"."user_id" AS "new_user_id", "User"."user_id"};
    is( $q->_select_clause($dbh), $sql,
        '_select_clause with column and alias for that column'
      );
}

{
    my $q = Fey::SQL->new_select();
    $q->select( $s->table('User')->column('user_id') )->distinct();

    my $sql = q{SELECT DISTINCT "User"."user_id"};
    is( $q->_select_clause($dbh), $sql, '_select_clause with distinct' );
}

{
    my $q = Fey::SQL->new_select();

    $q->select( 'some literal thing' );
    my $sql = q{SELECT 'some literal thing'};
    is( $q->_select_clause($dbh), $sql,
        '_select_clause after passing string to select()' );
}

{
    my $q = Fey::SQL->new_select();

    $q->select( 235.12 );
    my $sql = q{SELECT 235.12};
    is( $q->_select_clause($dbh), $sql,
        '_select_clause after passing number to select()' );
}

{
    my $q = Fey::SQL->new_select();

    my $concat =
        Fey::Literal::Function->new( 'CONCAT',
                                     $s->table('User')->column('user_id'),
                                     Fey::Literal::String->new(' '),
                                     $s->table('User')->column('username'),
                                   );
    $q->select($concat);

    my $lit_with_alias = q{CONCAT("User"."user_id", ' ', "User"."username") AS "FUNCTION0"};
    my $sql = 'SELECT '. $lit_with_alias;
    is( $q->_select_clause($dbh), $sql,
        '_select_clause after passing function to select()' );
}
