use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 19;

use Q::Query;


my $s = Q::Test->mock_test_schema_with_fks();

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    eval { $q->where() };
    like( $@, qr/0 parameters/,
          'where() without any parameters is an error' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where( $s->table('User')->column('user_id'), '=', 1 );

    is( $q->_where_clause(), q{WHERE "User"."user_id" = 1},
        'simple comparison - col = literal' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where
        ( $s->table('User')->column('user_id')->alias( alias_name => 'alias' ),
          '=', 1 );

    is( $q->_where_clause(), q{WHERE "alias" = 1},
        'simple comparison - col alias = literal' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where( $s->table('User')->column('username'), 'LIKE',
               '%foo%' );

    is( $q->_where_clause(), q{WHERE "User"."username" LIKE '%foo%'},
        'simple comparison - col LIKE literal' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where( 1, '=', $s->table('User')->column('user_id') );

    is( $q->_where_clause(), q{WHERE 1 = "User"."user_id"},
        'simple comparison - literal = col' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where( $s->table('User')->column('user_id'), '=', $s->table('User')->column('user_id') );

    is( $q->_where_clause(), q{WHERE "User"."user_id" = "User"."user_id"},
        'simple comparison - col = col' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where( $s->table('User')->column('user_id'), 'IN', 1, 2, 3 );

    is( $q->_where_clause(), q{WHERE "User"."user_id" IN (1, 2, 3)},
        'simple comparison - IN' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where( $s->table('User')->column('user_id'), 'NOT IN', 1, 2, 3 );

    is( $q->_where_clause(), q{WHERE "User"."user_id" NOT IN (1, 2, 3)},
        'simple comparison - IN' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where( $s->table('User')->column('user_id'), '=',
               $q->placeholder() );

    is( $q->_where_clause(), q{WHERE "User"."user_id" = ?},
        'simple comparison - col = placeholder' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    my $sub = Q::Query->new( dbh => $s->dbh() )->select();
    $sub->select( $s->table('User')->column('user_id') );
    $sub->from( $s->table('User') );

    $q->where( $s->table('User')->column('user_id'), 'IN', $sub );

    is( $q->_where_clause(), q{WHERE "User"."user_id" IN (( SELECT "User"."user_id" FROM "User" ))},
        'comparison with subselect' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where( $s->table('User')->column('user_id'), '=', undef );

    is( $q->_where_clause(), q{WHERE "User"."user_id" IS NULL},
        'undef in comparison (=)' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where( $s->table('User')->column('user_id'), '!=', undef );

    is( $q->_where_clause(), q{WHERE "User"."user_id" IS NOT NULL},
        'undef in comparison (!=)' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where( $s->table('User')->column('user_id'), 'BETWEEN', 1, 5 );

    is( $q->_where_clause(), q{WHERE "User"."user_id" BETWEEN 1 AND 5},
        'simple comparison - BETWEEN' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where( $s->table('User')->column('user_id'), '=', 1 );
    $q->where( $s->table('User')->column('user_id'), '=', 2 );

    is( $q->_where_clause(), q{WHERE "User"."user_id" = 1 AND "User"."user_id" = 2},
        'multiple clauses with implicit AN' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where( $s->table('User')->column('user_id'), '=', 1 );
    $q->or();
    $q->where( $s->table('User')->column('user_id'), '=', 2 );

    is( $q->_where_clause(), q{WHERE "User"."user_id" = 1 OR "User"."user_id" = 2},
        'multiple clauses with OR' );
}


{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->subgroup_start();
    $q->where( $s->table('User')->column('user_id'), '=', 2 );
    $q->subgroup_end();

    is( $q->_where_clause(), q{WHERE ( "User"."user_id" = 2 )},
        'subgroup in where clause' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    eval { $q->where( $s->table('User')->column('user_id'), '=', 1, 2 ) };
    like( $@, qr/more than one right-hand side/,
          'error when passing more than one RHS with =' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    my $sub = Q::Query->new( dbh => $s->dbh() )->select();
    $sub->select( $s->table('User')->column('user_id') );
    $sub->from( $s->table('User') );

    eval { $q->where( $s->table('User')->column('user_id'), 'LIKE', $sub ) };
    like( $@, qr/use a subselect on the right-hand side/,
          'error when passing subselect with LIKE' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    eval { $q->where( $s->table('User')->column('user_id'), 'BETWEEN', 1 ) };
    like( $@, qr/requires two arguments/,
          'error when passing one RHS with BETWEEN' );
}
