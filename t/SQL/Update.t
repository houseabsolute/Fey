use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More tests => 15;

use Fey::SQL;


my $s = Fey::Test->mock_test_schema();
my $dbh = Fey::Test->mock_dbh();

my $size =
    Fey::Column->new( name        => 'size',
                      type        => 'text',
                      is_nullable => 1,
                    );
$s->table('User')->add_column($size);

{
    eval { Fey::SQL::Update->new( dbh => $dbh )->update() };

    like( $@, qr/1 was expected/,
          'update() without any parameters fails' );
}

{
    my $q = Fey::SQL::Update->new( dbh => $dbh )->update( $s->table('User') );

    is( $q->_update_clause(), q{UPDATE "User"},
        'update clause for one table' );
}

{
    my $q = Fey::SQL::Update->new( dbh => $dbh )
                            ->update( $s->table('User'), $s->table('UserGroup') );

    is( $q->_update_clause(), q{UPDATE "User", "UserGroup"},
        'update clause for two tables' );
}

{
    my $q = Fey::SQL::Update->new( dbh => $dbh );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'), 'bubba' );

    is( $q->_set_clause(), q{SET "User"."username" = 'bubba'},
        '_set_clause() for one column' );
}

{
    my $q = Fey::SQL::Update->new( dbh => $dbh );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'), 'bubba',
             $s->table('User')->column('email'), 'bubba@bubba.com',
           );

    is( $q->_set_clause(),
        q{SET "User"."username" = 'bubba', "User"."email" = 'bubba@bubba.com'},
        '_set_clause() for two columns' );
}

{
    my $q = Fey::SQL::Update->new( dbh => $dbh );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             $s->table('User')->column('email'),
           );

    is( $q->_set_clause(),
        q{SET "User"."username" = "User"."email"},
        '_set_clause() for column = columns' );
}

{
    my $q = Fey::SQL::Update->new( dbh => $dbh );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('size'),
             Fey::Literal->new_from_scalar(undef),
           );

    is( $q->_set_clause(),
        q{SET "User"."size" = NULL},
        '_set_clause() for column = NULL (literal)' );
}

{
    my $q = Fey::SQL::Update->new( dbh => $dbh );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             Fey::Literal->new_from_scalar('string'),
           );

    is( $q->_set_clause(),
        q{SET "User"."username" = 'string'},
        '_set_clause() for column = string (literal)' );
}

{
    my $q = Fey::SQL::Update->new( dbh => $dbh );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             Fey::Literal->new_from_scalar(42),
           );

    is( $q->_set_clause(),
        q{SET "User"."username" = 42},
        '_set_clause() for column = number (literal)' );
}

{
    my $q = Fey::SQL::Update->new( dbh => $dbh );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             Fey::Literal::Function->new( 'NOW' ),
           );

    is( $q->_set_clause(),
        q{SET "User"."username" = NOW()},
        '_set_clause() for column = function (literal)' );
}

{
    my $q = Fey::SQL::Update->new( dbh => $dbh );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             Fey::Literal::Term->new( 'thingy' ),
           );

    is( $q->_set_clause(),
        q{SET "User"."username" = thingy},
        '_set_clause() for column = term (literal)' );
}

{
    my $q = Fey::SQL::Update->new( dbh => $dbh );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             Fey::Literal::Term->new( 'thingy' ),
           );

    is( $q->_set_clause(),
        q{SET "User"."username" = thingy},
        '_set_clause() for column = term (literal)' );
}

{
    my $q = Fey::SQL::Update->new( dbh => $dbh );
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

{
    my $q = Fey::SQL::Update->new( dbh => $dbh );
    $q->update( $s->table('User') );
    eval { $q->set() };

    like( $@, qr/list of paired/,
          'set() called with no parameters' );
}

{
    my $q = Fey::SQL::Update->new( dbh => $dbh );
    $q->update( $s->table('User') );
    eval { $q->set( $s->table('User')->column('username') ) };

    like( $@, qr/list of paired/,
          'set() called with one parameter' );
}
