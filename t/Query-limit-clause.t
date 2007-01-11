use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More tests => 3;

use Fey::Literal;
use Fey::Query;


my $s = Fey::Test->mock_test_schema_with_fks();

{
    my $q = Fey::Query->new( dbh => $s->dbh() );

    eval { $q->limit() };
    like( $@, qr/0 parameters/,
          'at least one parameter is required for limit()' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() );

    $q->limit(10);

    is( $q->_limit_clause(), 'LIMIT 10',
        'simple limit clause' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() );

    $q->limit( 10, 20 );

    is( $q->_limit_clause(), 'LIMIT 10 OFFSET 20',
        'limit clause with offset' );
}
