use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 14;


use_ok( 'Q::Table' );

{
    eval { my $s = Q::Table->new() };
    like( $@, qr/Mandatory parameter 'name' missing/,
          'name is a required param' );
}

{
    my $t = Q::Table->new( name => 'Test' );

    is( $t->name(), 'Test', 'table name is Test' );
    ok( ! $t->is_view(), 'table is not view' );
}

{
    my $t = Q::Table->new( name => 'Test', is_view => 1 );

    ok( $t->is_view(), 'table is view' );
}

{
    my $t = Q::Table->new( name => 'Test' );
    my $c1 = Q::Column->new( name         => 'test_id',
                             type         => 'text',
                             generic_type => 'text',
                           );

    $t->add_column($c1);
    ok( $t->column('test_id'), 'test_id column is in table' );

    my @cols = $t->columns;
    is( scalar @cols, 1, 'table has one column' );
    is( $cols[0], $c1, 'columns() returned one column - test_id' );

    eval { $t->add_column($c1) };
    like( $@, qr/already has a column named test_id/,
          'cannot add a column twice' );

    $t->remove_column($c1);
    ok( ! $t->column('test_id'), 'test_id column is not in table' );
}

{
    my $t = Q::Table->new( name => 'Test' );
    my $c1 = Q::Column->new( name         => 'test_id',
                             type         => 'text',
                             generic_type => 'text',
                           );

    my $c2 = Q::Column->new( name         => 'size',
                             type         => 'integer',
                             generic_type => 'integer',
                           );

    $t->add_column($_) for $c1, $c2;

    is( scalar $t->columns, 2, 'table has two columns' );

    eval { $t->set_primary_key('no_such_thing') };
    like( $@, qr/The column no_such_thing is not part of the Test table./,
          'add_key() called with invalid column name' );

    $t->set_primary_key('test_id');
    my @pk = $t->primary_key();
    is( scalar @pk, 1, 'table has a one column pk' );
    is( $pk[0]->name(), 'test_id', 'pk column is test_id' );
}
