use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 3;

use Q::Query;


my $s = Q::Test->mock_test_schema();

{
    eval { my $q = Q::Query->new() };
    like( $@, qr/Mandatory parameter .+ missing/,
          'dbh is a required param' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() );
    isa_ok( $q, 'Q::Query' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() );

    $q->select( $s->table('User') );
    isa_ok( $q, 'Q::Query::Select' );
}

