use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 18;

use Q::FK;
use Q::Schema;


{
    my $s = Q::Test->mock_test_schema();

    eval { Q::FK->new( source => $s->table('User')->column('user_id'),
                       target => [ $s->table('UserGroup')->column('user_id'),
                                   $s->table('UserGroup')->column('group_id'),
                                 ],
                     ) };
    like( $@, qr/must contain the same number of columns/,
          'error when column count for source and target differ' );

    eval { Q::FK->new( source => [ $s->table('User')->column('user_id'),
                                   $s->table('User')->column('username'),
                                 ],
                       target => [ $s->table('UserGroup')->column('user_id'),
                                   $s->table('User')->column('username'),
                                 ],
                     ) };
    my $err =
        'Each column in the target argument to add_foreign_key()'
        . ' must come from the same table.';
    like( $@, qr/\Q$err/,
          'error when column list comes from >1 table' );

    my $c = Q::Column->new( name => 'no_table',
                            type => 'text',
                          );
    eval { Q::FK->new( source => $s->table('User')->column('user_id'),
                       target => $c,
                     ) };
    like( $@, qr/\QAll columns passed to add_foreign_key() must have a table./,
          'error when a column does not have a table' );

    my $fk =
        Q::FK->new
            ( source => $s->table('User')->column('user_id'),
              target => $s->table('UserGroup')->column('user_id'),
            );

    is( $fk->source_table()->name(), 'User',
        'source_table() is User' );
    is( $fk->target_table()->name(), 'UserGroup',
        'source_table() is UserEmail' );

    my @source = $fk->source_columns();
    is( scalar @source, 1, 'one source column' );
    is( $source[0]->name(), 'user_id', 'source column is user_id' );

    my @target = $fk->target_columns();
    is( scalar @target, 1, 'one target column' );
    is( $target[0]->name(), 'user_id', 'target column is user_id' );

    my $fk2 =
        Q::FK->new
            ( target => $s->table('User')->column('user_id'),
              source => $s->table('UserGroup')->column('user_id'),
            );

    is( $fk->id(), $fk2->id(),
        'id for an fk is the same regardless of source and target' );

    ok( $fk->has_tables( 'User', 'UserGroup' ),
        'has_tables() is true for User and UserGroup - as strings' );
    ok( $fk->has_tables( $s->table('User'), $s->table('UserGroup') ),

        'has_tables() is true for User and UserGroup - as objects' );
    ok( ! $fk->has_tables( 'User', 'Group' ),
        'has_tables() is false for User and Group - as strings' );
    ok( ! $fk->has_tables( $s->table('User'), $s->table('Group') ),
        'has_tables() is false for User and Group - as objects' );
    ok( ! $fk->has_tables( 'Message', 'Group' ),
        'has_tables() is false for Message and Group - as strings' );
    # Need to test where first in sorted order is present and second
    # is not for full coverage.
    ok( ! $fk->has_tables( 'User', 'Z' ),
        'has_tables() is false for User and Z - as strings' );

    ok( ! $fk->has_column( $s->table('User')->column('username') ),
        'fk does not have User.username column' );
    ok( ! $fk->has_column( $s->table('Group')->column('group_id') ),
        'fk does have Group.group_id column' );
}
