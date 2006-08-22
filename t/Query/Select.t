use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 1;

use Q::Query;


{
    my $s = Q::Test->mock_test_schema();

    my $q = Q::Query->new( dbh => $s->dbh() );

    $q->select( $s->table('User') );
    is( $q->_start_clause,
        'SELECT User.email, User.username, User.user_id',
        '_start_clause returns expected SELECT'
      )

    $q->select( $s->table('User') );

    
}
