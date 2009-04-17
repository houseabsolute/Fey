use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More tests => 4;

use Fey::SQL;


my $s = Fey::Test->mock_test_schema();
my $dbh = Fey::Test->mock_dbh();

my $size =
    Fey::Column->new( name        => 'size',
                      type        => 'text',
                      is_nullable => 1,
                    );
$s->table('User')->add_column($size);

{
    eval { Fey::SQL->new_delete()->delete()->from() };

    like( $@, qr/1 was expected/,
          'from() without any parameters fails' );
}

{
    my $delete = Fey::SQL->new_delete()->delete()->from( $s->table('User') );

    is( $delete->delete_clause($dbh), q{DELETE FROM "User"},
        'delete clause for one table' );
}

{
    my $delete = Fey::SQL->new_delete()
                         ->delete()->from( $s->table('User'), $s->table('UserGroup') );

    is( $delete->delete_clause($dbh), q{DELETE FROM "User", "UserGroup"},
        'delete clause for two tables' );
}

{
    my $delete = Fey::SQL->new_delete( auto_placeholders => 0 );
    $delete->delete()->from( $s->table('User') );
    $delete->where( $s->table('User')->column('user_id'), '=', 10 );
    $delete->order_by( $s->table('User')->column('user_id') );
    $delete->limit(10);

    is( $delete->sql($dbh),
        q{DELETE FROM "User" WHERE "User"."user_id" = 10 ORDER BY "User"."user_id" LIMIT 10},
        'delete sql with where clause, order by, and limit' );
}
