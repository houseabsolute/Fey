use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 3;


use_ok('Q::Query::Formatter');

require Q::Literal;


my $s = Q::Test->mock_test_schema();

{
    my $f = Q::Query::Formatter->new( dbh => $s->dbh() );

    my $concat = Q::Literal->function( 'CONCAT',
                                       $s->table('User')->column('user_id'),
                                       Q::Literal->string(' '),
                                       $s->table('User')->column('username'),
                                     );

    my $lit_with_alias = q{CONCAT("User"."user_id", ' ', "User"."username") AS FUNCTION0};
    is( $f->_literal_and_alias($concat), $lit_with_alias,
        '_literal_and_alias for a function' );
    is( $f->_literal_and_alias($concat), $lit_with_alias,
        '_literal_and_alias returns same alias for function second time' );
}
