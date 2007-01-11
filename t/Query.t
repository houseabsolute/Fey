use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More tests => 3;

use Fey::Query;


my $s = Fey::Test->mock_test_schema();

{
    eval { my $q = Fey::Query->new() };
    like( $@, qr/Mandatory parameter .+ missing/,
          'dbh is a required param' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() );
    isa_ok( $q, 'Fey::Query' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() );

    $q->select( $s->table('User') );
    isa_ok( $q, 'Fey::Query::Select' );
}

