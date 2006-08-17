use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 7;


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

{
    my $s = Q::Schema->new( name => 'Test' );
    my $t = Q::Table->new( name => 'Test' );

    ok( ! $t->schema(), 'table has no schema when created' );

    $s->add_table($t);
    is( $t->schema(), $s,
        'table has a schema after calling add_table()' );

    $s->remove_table($t);

    ok( ! $t->schema(),
        'table has no schema after calling remove_table()' );
}
