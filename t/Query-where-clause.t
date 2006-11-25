use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 7;

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

    is( $q->_where_clause(), q{"User"."user_id" = 1},
        'simple comparison - col = literal' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where( $s->table('User')->column('username'), 'LIKE',
               '%foo%' );

    is( $q->_where_clause(), q{"User"."username" LIKE '%foo%'},
        'simple comparison - col LIKE literal' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where( 1, '=', $s->table('User')->column('user_id') );

    is( $q->_where_clause(), q{1 = "User"."user_id"},
        'simple comparison - literal = col' );
}


{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where( $s->table('User')->column('user_id'), '=', $s->table('User')->column('user_id') );

    is( $q->_where_clause(), q{"User"."user_id" = "User"."user_id"},
        'simple comparison - col = col' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->where( $s->table('User')->column('user_id'), '=',
               $q->placeholder() );

    is( $q->_where_clause(), q{"User"."user_id" = ?},
        'simple comparison - col = placeholder' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    my $sub = Q::Query->new( dbh => $s->dbh() )->select();
    $sub->select( $s->table('User')->column('user_id') );
    $sub->from( $s->table('User') );

    $q->where( $s->table('User')->column('user_id'), 'IN', $sub );

    is( $q->_where_clause(), q{"User"."user_id" IN ( SELECT "User"."user_id" FROM "User" )},
        'simple comparison - col = placeholder' );
}
