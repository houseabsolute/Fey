use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 7;


use_ok('Q::Query');

{
    eval { my $s = Q::Query->new() };
    like( $@, qr/Mandatory parameter .+ missing/,
          'dbh is a required param' );
}

{
    my $s = Q::Test->mock_test_schema();

    my $q = Q::Query->new( dbh => $s->dbh() );
    isa_ok( $q, 'Q::Query' );
    eval { $q->_start_clause() };
    like( $@, qr/\QThe _start_clause() method must be overridden/,
          'Cannot call _start_clause on a Q::Query object' );

    $q->select( $s->table('User') );

    isa_ok( $q, 'Q::Query::Select' );

    is( $q->quote('Simple'), q{'Simple'},
        'quote on simple string' );
    is( $q->quote(q{Won't}), q{'Won''t'},
        'quote on string with apostrophe' );
}
