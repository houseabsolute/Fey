use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More;

unless (
    eval {
        require Test::Memory::Cycle;
        Test::Memory::Cycle->import();
        1;
    }
    ) {
    plan skip_all => 'These tests require Test::Memory::Cycle.';
    exit;
}


memory_cycle_ok(
    Fey::Test->mock_test_schema(),
    'Make sure schema object does not have circular refs'
);

done_testing();
