use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More;

unless ( eval { require Test::Memory::Cycle;
                Test::Memory::Cycle->import();
                1; } )
{
    plan skip_all => 'These tests require Test::Memory::Cycle.';
    exit;
}

plan tests => 1;

memory_cycle_ok( Q::Test->mock_test_schema(),
                 'Make sure schema object does not have circular refs' );
