use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 13;

use Q::Query;

my $s = Q::Test->mock_test_schema();

{
    eval { Q::Query->new( dbh => $s->dbh() )->update() };

    like( $@, qr/1 was expected/,
          'update() without any parameters fails' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->update( $s->table('User') );

    is( $q->_update_clause(), q{UPDATE "User"},
        'update clause for one table' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )
                    ->update( $s->table('User'), $s->table('UserGroup') );

    is( $q->_update_clause(), q{UPDATE "User", "UserGroup"},
        'update clause for two tables' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'), 'bubba' );

    is( $q->_set_clause(), q{SET "User"."username" = 'bubba'},
        'set clause for one column' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'), 'bubba',
             $s->table('User')->column('email'), 'bubba@bubba.com',
           );

    is( $q->_set_clause(),
        q{SET "User"."username" = 'bubba', "User"."email" = 'bubba@bubba.com'},
        'set clause for two columns' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             $s->table('User')->column('email'),
           );

    is( $q->_set_clause(),
        q{SET "User"."username" = "User"."email"},
        'set clause for column = columns' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             Q::Literal->new_from_scalar(undef),
           );

    is( $q->_set_clause(),
        q{SET "User"."username" = NULL},
        'set clause for column = NULL (literal)' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             Q::Literal->new_from_scalar('string'),
           );

    is( $q->_set_clause(),
        q{SET "User"."username" = 'string'},
        'set clause for column = string (literal)' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             Q::Literal->new_from_scalar(42),
           );

    is( $q->_set_clause(),
        q{SET "User"."username" = 42},
        'set clause for column = number (literal)' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             Q::Literal->function( 'NOW' ),
           );

    is( $q->_set_clause(),
        q{SET "User"."username" = NOW()},
        'set clause for column = function (literal)' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             Q::Literal->term( 'thingy' ),
           );

    is( $q->_set_clause(),
        q{SET "User"."username" = thingy},
        'set clause for column = term (literal)' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             Q::Literal->term( 'thingy' ),
           );

    is( $q->_set_clause(),
        q{SET "User"."username" = thingy},
        'set clause for column = term (literal)' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             'hello'
           );
    $q->where( $s->table('User')->column('user_id'), '=', 10 );
    $q->order_by( $s->table('User')->column('user_id') );
    $q->limit(10);

    is( $q->sql(),
        q{UPDATE "User" SET "User"."username" = 'hello' WHERE "User"."user_id" = 10 ORDER BY "User"."user_id" LIMIT 10},
        'update sql with where clause, order by, and limit' );
}
