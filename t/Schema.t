use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 4;


use_ok( 'Q::Schema' );

{
    eval { my $s = Q::Schema->new() };
    like( $@, qr/Mandatory parameter .+ missing/,
          'dbh is a required param' );
}

{
    my $s = Q::Schema->new( name => 'Test' );

    is( $s->name(), 'Test', 'schema name is Test' );

    $s->set_dbh( Q::Test->mock_dbh );
    ok( $s->dbh(), 'set_dbh() sets the database handle' );
}
