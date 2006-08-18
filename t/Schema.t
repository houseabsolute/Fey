use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 24;


use_ok( 'Q::Schema' );

{
    eval { my $s = Q::Schema->new() };
    like( $@, qr/Mandatory parameter .+ missing/,
          'dbh is a required param' );
}

{
    my $s = Q::Schema->new( name => 'Test' );

    is( $s->name(), 'Test', 'schema name is Test' );

    $s->set_dbh( Q::Test->mock_dbh );
    ok( $s->dbh(), 'set_dbh() sets the database handle' );
}

{
    my $s = Q::Schema->new( name => 'Test' );
    my $t = Q::Table->new( name => 'Test' );

    ok( ! $t->schema(), 'table has no schema when created' );

    $s->add_table($t);
    is( $t->schema(), $s,
        'table has a schema after calling add_table()' );
    is( $s->table( $t->name() ), $t,
        'table is in schema' );

    $s->remove_table($t);
    ok( ! $t->schema(),
        'table has no schema after calling remove_table()' );
    ok( ! $s->table( $t->name() ), 'table is not in schema' );

    $s->add_table($t);
    $s->remove_table( $t->name() );
    ok( ! $t->schema(),
        'table has no schema after calling remove_table()' );
}

{
    require Q::FK;

    my $s = Q::Test->mock_test_schema();

    my $fk =
        Q::FK->new
            ( source => $s->table('User')->column('user_id'),
              target => $s->table('UserGroup')->column('user_id'),
            );

    $s->add_foreign_key($fk);

    {
        my @fk = $s->foreign_keys_for_table('User');
        is( scalar @fk, 1, 'one fk for User table - passed as name' );
    }

    my @fk = $s->foreign_keys_for_table( $s->table('User') );
    is( scalar @fk, 1, 'one fk for User table - passed as object' );
    is( $fk[0]->source_table()->name(), 'User',
        'source table is user' );
    is( ($fk[0]->source_columns())[0]->name(), 'user_id',
        'source column is user_id' );

    $s->add_foreign_key($fk);
    @fk = $s->foreign_keys_for_table('User');
    is( scalar @fk, 1, 'one fk for User table - dupes are ignored' );

    @fk = $s->foreign_keys_for_table('UserGroup');
    is( scalar @fk, 1, 'one fk for UserGroup table' );
    is( $fk[0]->id(), $fk->id(),
        'foreign key for UserGroup is same as original fk' );

    @fk = $s->foreign_keys_between_tables( 'User', 'UserGroup' );
    is( scalar @fk, 1, 'one fk for UserGroup table' );
    is( $fk[0]->id(), $fk->id(),
        'one foreign key between User and UserGroup is same as original' );

    @fk = $s->foreign_keys_between_tables( $s->table('User'), $s->table('UserGroup') );
    is( scalar @fk, 1, 'one fk for UserGroup table - passed as objects' );

    @fk = $s->foreign_keys_between_tables( 'User', 'Group' );
    is( scalar @fk, 0, 'no fks between User and Group' );

    $s->remove_foreign_key($fk);
    @fk = $s->foreign_keys_for_table('User');
    is( scalar @fk, 0, 'no fks for User table' );

    $s->add_foreign_key($fk);
    my $user_t = $s->table('User');
    $s->remove_table('User');
    @fk = $s->foreign_keys_for_table('UserGroup');
    is( scalar @fk, 0,
        'no fks for UserGroup table after User table is removed' );

    $s->add_table($user_t);
    $fk =
        Q::FK->new
            ( source => $s->table('User')->column('user_id'),
              target => $s->table('UserGroup')->column('user_id'),
            );
    $s->add_foreign_key($fk);

    $user_t->remove_column('user_id');
    @fk = $s->foreign_keys_for_table('UserGroup');
    is( scalar @fk, 0,
        'no fks for UserGroup table after User.user_id column is removed' );
}
