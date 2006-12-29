use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 4;

use Q::Loader;

{
    my $warnings = '';
    local $SIG{__WARN__} = sub { $warnings .= $_ for @_ };

    my $loader = Q::Loader->new( dbh => Q::Test->mock_dbh() );
    like( $warnings, qr/no driver-specific Q::Loader subclass/,
          'warning was emitted when we could not find a driver-specific load subclass' );

    isa_ok( $loader, 'Q::Loader::DBI' );
}

{
    my $dbh = Q::Test->mock_dbh();
    $dbh->{Driver}{Name} = 'SQLite';

    my $loader = Q::Loader->new( dbh => $dbh );
    isa_ok( $loader, 'Q::Loader::SQLite' );

    # Make sure Q::Loader finds the right subclass after that subclass
    # has been loaded.
    $loader = Q::Loader->new( dbh => $dbh );
    isa_ok( $loader, 'Q::Loader::SQLite' );
}

