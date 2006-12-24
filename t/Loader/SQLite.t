use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Q::Test::Loader;
use Q::Test::SQLite;

use Test::More tests => 124;

use Q::Loader;


{
    my $loader = Q::Loader->new( dbh => Q::Test::SQLite->dbh() );

    my $schema1 = $loader->make_schema( name => 'Test' );
    my $schema2 = Q::Test->mock_test_schema_with_fks();

    Q::Test::Loader->compare_schemas
        ( $schema1, $schema2,
          { 'Message.quality'      => { type => 'real' },
            # SQLite crack-headedly returns the actual current date as
            # the default value if we use CURRENT_DATE as the
            # default. Brilliant!
            'Message.message_date' => { default => undef },
            skip_foreign_keys => 1,
          },
        );
}

{
    is( Q::Loader::SQLite->_default('NULL'), undef,
        'NULL as default becomes undef' );

    is( Q::Loader::SQLite->_default('foo'), 'foo',
        q{foo as default becomes string foo} );

    is( Q::Loader::SQLite->_default(42), 42,
        '42 as default becomes 42' );

    is( Q::Loader::SQLite->_default(42.42), 42.42,
        '42.42 as default becomes 42.42' );

    my $def = Q::Loader::SQLite->_default('CURRENT_TIME');
    isa_ok( $def, 'Q::Literal::Term' );
    is( $def->sql, 'CURRENT_TIME',
        'unquoted CURRENT_TIME as default becomes CURRENT_TIME as term' );
}
