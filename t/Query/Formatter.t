use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 14;


use_ok('Q::Query::Formatter');

require Q::Literal;


my $s = Q::Test->mock_test_schema();

{
    my $f = Q::Query::Formatter->new( dbh => $s->dbh() );

    my $concat = Q::Literal->function( 'CONCAT',
                                       $s->table('User')->column('user_id'),
                                       Q::Literal->string(' '),
                                       $s->table('User')->column('username'),
                                     );

    my $lit_with_alias = q{CONCAT("User"."user_id", ' ', "User"."username") AS FUNCTION0};
    is( $f->_literal_and_alias($concat), $lit_with_alias,
        '_literal_and_alias for a function' );
    is( $f->_literal_and_alias($concat), $lit_with_alias,
        '_literal_and_alias returns same alias for function second time' );
}

{
    my $f = Q::Query::Formatter->new( dbh => $s->dbh() );

    my $col = $s->table('User')->column('user_id');
    is( $f->format_for_select($col), q{"User"."user_id"},
        'format_for_select() with column' );

    my $alias = $col->alias( alias_name => 'uid' );
    is( $f->format_for_select($alias), q{"User"."user_id" AS "uid"},
        'format_for_select() with alias' );

    my $t_alias = $s->table('User')->alias( alias_name => 'User1' );
    is ( $f->format_for_select( $t_alias->column('user_id') ),
         q{"User1"."user_id"},
         'format_for_select() with column from table alias' );

    my $alias2 = $t_alias->column('user_id')->alias( alias_name => 'uid' );
    is ( $f->format_for_select($alias2),
         q{"User1"."user_id" AS "uid"},
         'format_for_select() with column alias from table alias' );

    my $func = Q::Literal->function('NOW');
    is( $f->format_for_select($func), q{NOW() AS FUNCTION0},
        'format_for_select() with function' );
}

{
    my $f = Q::Query::Formatter->new( dbh => $s->dbh() );

    my $t = $s->table('User');
    is( $f->_table_name_for_from($t), q{"User"},
        '_table_name_for_from() with table' );

    my $alias = $t->alias( alias_name => 'User1' );
    is( $f->_table_name_for_from($alias), q{"User" AS "User1"},
        '_table_name_for_from() with table' );
}

{
    my $f = Q::Query::Formatter->new( dbh => $s->dbh() );

    my $col = $s->table('User')->column('user_id');
    is( $f->_lhs_for_where($col), q{"User"."user_id"},
        '_lhs_for_where() with column' );

    my $alias = $col->alias( alias_name => 'uid' );
    is( $f->_lhs_for_where($alias), q{"uid"},
        '_lhs_for_where() with column alias' );

    my $t_alias = $s->table('User')->alias( alias_name => 'User1' );
    is ( $f->_lhs_for_where( $t_alias->column('user_id') ),
         q{"User1"."user_id"},
         '_lhs_for_where() with column from table alias' );

    my $alias2 = $t_alias->column('user_id')->alias( alias_name => 'uid' );
    is ( $f->_lhs_for_where($alias2),
         q{"uid"},
         '_lhs_for_where() with column alias from table alias' );
}
