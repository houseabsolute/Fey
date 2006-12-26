use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Q::Test::Loader;
use Q::Test::Pg;

use Test::More tests => 127;

use Q::Loader;


{
    my $loader = Q::Loader->new( dbh => Q::Test::SQLite->dbh() );

    my $schema1 = $loader->make_schema( name => 'Test' );
    my $schema2 = Q::Test->mock_test_schema_with_fks();

    Q::Test::Loader->compare_schemas
        ( $schema1, $schema2,
          { 'Message.message_date' =>
                { default => Q::Literal->function('now'),
                },
            'Message.quality' =>
                { type => 'numeric',
                },
            'Message.message' =>
                { type   => 'character varying',
                  length => 255,
                },
          },
        );
}

{
    my $def = Q::Loader::Pg->_default('NULL');
    isa_ok( $def, 'Q::Literal::Null');
}
