use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Q::Test::Loader;

use Test::More tests => 129;

use Q::Loader;


{
    my $loader =
        do { local $SIG{__WARN__} =
                 sub { my @w = grep { ! /driver-specific/ } @_;
                       warn @w if @w; };
             Q::Loader->new( dbh => Q::Test->mock_dbh() ) };

    my $schema1 = $loader->make_schema();
    my $schema2 = Q::Test->mock_test_schema_with_fks();

    Q::Test::Loader->compare_schemas
        ( $schema1, $schema2,
          { 'Group.group_id'     => { is_auto_increment => 0 },
            'Message.message_id' => { is_auto_increment => 0 },
            'User.user_id'       => { is_auto_increment => 0 },
          },
        );
}

{
    is( Q::Loader::DBI->_default('NULL'), undef,
        'NULL as default becomes undef' );

    is( Q::Loader::DBI->_default( q{'foo'} ), 'foo',
        q{'foo' as default becomes string foo} );

    is( Q::Loader::DBI->_default( q{"foo"} ), 'foo',
        q{"foo" as default becomes string foo} );

    is( Q::Loader::DBI->_default(42), 42,
        '42 as default becomes 42' );

    is( Q::Loader::DBI->_default(42.42), 42.42,
        '42.42 as default becomes 42.42' );

    my $def = Q::Loader::DBI->_default('NOW');
    isa_ok( $def, 'Q::Literal::Term' );
    is( $def->sql, 'NOW',
        'unquoted NOW as default becomes NOW as term' );
}
