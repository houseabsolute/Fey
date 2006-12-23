use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Q::Test::Loader;
use Q::Test::SQLite;

use Test::More tests => 119;

use Q::Loader;


{
    my $loader = Q::Loader->new( dbh => Q::Test::SQLite->dbh() );

    my $schema1 = $loader->make_schema();
    my $schema2 = Q::Test->mock_test_schema_with_fks();

    Q::Test::Loader->compare_schemas( $schema1, $schema2 );
}
