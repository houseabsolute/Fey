use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 1;


use_ok('Q::Query');

{
    my $s = Q::Test->mock_test_schema();
}
