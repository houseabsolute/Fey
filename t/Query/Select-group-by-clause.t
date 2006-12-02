use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 6;

use Q::Literal;
use Q::Query;


my $s = Q::Test->mock_test_schema_with_fks();

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    eval { $q->group_by() };
    like( $@, qr/0 parameters/,
          'at least one parameter is required for group_by()' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->group_by( $s->table('User')->column('user_id') );
    is( $q->_group_by_clause(), q{GROUP BY "User"."user_id"},
        'group_by() one column' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->group_by( $s->table('User')->column('user_id'),
                  $s->table('User')->column('username')
                );
    is( $q->_group_by_clause(), q{GROUP BY "User"."user_id", "User"."username"},
        'group_by() two columns' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->group_by( $s->table('User')->column('user_id')
                  ->alias( alias_name => 'alias_test' ) );

    is( $q->_group_by_clause(), q{GROUP BY "alias_test"},
        'group_by() column alias' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    my $now = Q::Literal->function( 'NOW' );
    $now->_make_alias();

    $q->group_by($now);

    like( $q->_group_by_clause(), qr/GROUP BY "FUNCTION\d+"/,
        'group_by() function' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    my $term = Q::Literal->term( q{"Foo"::text} );
    $q->group_by($term);

    is( $q->_group_by_clause(), q{GROUP BY "Foo"::text},
        'group_by() term' );
}
