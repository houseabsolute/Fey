use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More tests => 4;

use Fey::SQL;


my $s = Fey::Test->mock_test_schema_with_fks();
my $dbh = Fey::Test->mock_dbh();


{
    my $q = Fey::SQL->new_insert()->insert();

    $q->into( $s->table('User')->columns( 'user_id', 'username' ) );

    $q->values( user_id => 1, username => 'bob' );

    is( $q->values_clause($dbh), q{VALUES (?, ?)},
        'values_clause() for normal insert' );
    is_deeply( [ $q->bind_params() ], [ 1, 'bob' ],
               q{bind_params() is [ 1, 'bob' ]} );
}

{
    my $q = Fey::SQL->new_insert()->insert();

    $q->into( $s->table('User')->columns('user_id', 'username') );

    $q->values( user_id => 1, username => 'bob' );
    $q->values( user_id => 2, username => 'faye' );

    is( $q->values_clause($dbh), q{VALUES (?, ?),(?, ?)},
        'values_clause() for extended insert' );
    is_deeply( [ $q->bind_params() ], [ 1, 'bob', 2, 'faye' ],
               q{bind_params() is [ 1, 'bob', 2, 'faye' ]} );
}
