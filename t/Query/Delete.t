use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 4;

use Q::Query;


my $s = Q::Test->mock_test_schema();

my $size =
    Q::Column->new( name        => 'size',
                    type        => 'text',
                    is_nullable => 1,
                  );
$s->table('User')->add_column($size);

{
    eval { Q::Query->new( dbh => $s->dbh() )->delete()->from() };

    like( $@, qr/1 was expected/,
          'from() without any parameters fails' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->delete()->from( $s->table('User') );

    is( $q->_delete_clause(), q{DELETE FROM "User"},
        'delete clause for one table' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )
                    ->delete()->from( $s->table('User'), $s->table('UserGroup') );

    is( $q->_delete_clause(), q{DELETE FROM "User", "UserGroup"},
        'delete clause for two tables' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() );
    $q->delete()->from( $s->table('User') );
    $q->where( $s->table('User')->column('user_id'), '=', 10 );
    $q->order_by( $s->table('User')->column('user_id') );
    $q->limit(10);

    is( $q->sql(),
        q{DELETE FROM "User" WHERE "User"."user_id" = 10 ORDER BY "User"."user_id" LIMIT 10},
        'delete sql with where clause, order by, and limit' );
}
