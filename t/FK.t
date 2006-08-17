use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 4;


use_ok('Q::FK');

{
    require Q::Schema;

    my $s = _make_test_schema();

    eval { Q::FK->new( source => $s->table('User')->column('user_id'),
                       target => [ $s->table('UserEmail')->column('user_id'),
                                   $s->table('UserEmail')->column('email'),
                                 ],
                     ) };
    like( $@, qr/must contain the same number of columns/,
          'error when column count for source and target differ' );

    eval { Q::FK->new( source => [ $s->table('User')->column('user_id'),
                                   $s->table('User')->column('name'),
                                 ],
                       target => [ $s->table('UserEmail')->column('user_id'),
                                   $s->table('User')->column('name'),
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
              target => $s->table('UserEmail')->column('user_id'),
            );

    is( $fk->source_table()->name(), 'User',
        'source_table() is User' );
    is( $fk->target_table()->name(), 'UserEmail',
        'source_table() is UserEmail' );

    my @source = $fk->source_columns();
    is( scalar @source, 1, 'one source column' );
    is( $source[0]->name(), 'user_id', 'source column is user_id' );

    my @target = $fk->target_columns();
    is( scalar @target, 1, 'one target column' );
    is( $target[0]->name(), 'user_id', 'target column is user_id' );
}


sub _make_test_schema
{
    my $s = Q::Schema->new( name => 'Test' );

    my $user_t = Q::Table->new( name => 'User' );
    my $user_id = Q::Column->new( name => 'user_id',
                                  type => 'integer',
                                );

    $user_t->add_column($user_id);
    $user_t->set_primary_key('user_id');

    my $name = Q::Column->new( name => 'name',
                               type => 'text',
                             );

    $user_t->add_column($name);

    $s->add_table($user_t);

    my $user_email_t = Q::Table->new( name => 'UserEmail' );
    my $email = Q::Column->new( name => 'email',
                                type => 'text',
                              );

    $user_email_t->add_column($email);
    $user_email_t->set_primary_key('email');

    my $user_id2 = Q::Column->new( name => 'user_id',
                                   type => 'integer',
                                 );
    $user_email_t->add_column($user_id2);

    $s->add_table($user_email_t);

    return $s;
}
