use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More tests => 3;

use Fey::SQL;


my $s = Fey::Test->mock_test_schema();
my $dbh = Fey::Test->mock_dbh();

{
    eval { my $q = Fey::SQL->new() };
    like( $@, qr/Mandatory parameter .+ missing/,
          'dbh is a required param' );
}

{
    my $q = Fey::SQL->new( dbh => $dbh );
    isa_ok( $q, 'Fey::SQL' );
}

{
    my $q = Fey::SQL->new( dbh => $dbh );

    $q->select( $s->table('User') );
    isa_ok( $q, 'Fey::SQL::Select' );
}

