use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More tests => 23;

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
    eval { Fey::SQL->new_update()->update() };

    like( $@, qr/1 was expected/,
          'update() without any parameters fails' );
}

{
    my $q = Fey::SQL->new_update()->update( $s->table('User') );

    is( $q->_update_clause($dbh), q{UPDATE "User"},
        'update clause for one table' );
}

{
    my $q = Fey::SQL->new_update()
                    ->update( $s->table('User'), $s->table('UserGroup') );

    is( $q->_update_clause($dbh), q{UPDATE "User", "UserGroup"},
        'update clause for two tables' );
}

{
    my $q = Fey::SQL->new_update( auto_placeholders => 0 );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'), 'bubba' );

    is( $q->_set_clause($dbh), q{SET "username" = 'bubba'},
        '_set_clause() for one column' );
}

{
    my $q = Fey::SQL->new_update( auto_placeholders => 0 );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'), 'bubba',
             $s->table('User')->column('email'), 'bubba@bubba.com',
           );

    is( $q->_set_clause($dbh),
        q{SET "username" = 'bubba', "email" = 'bubba@bubba.com'},
        '_set_clause() for two columns' );
}

{
    my $q = Fey::SQL->new_update();
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             $s->table('User')->column('email'),
           );

    is( $q->_set_clause($dbh),
        q{SET "username" = "User"."email"},
        '_set_clause() for column = columns' );
}

{
    my $q = Fey::SQL->new_update();
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('size'),
             Fey::Literal->new_from_scalar(undef),
           );

    is( $q->_set_clause($dbh),
        q{SET "size" = NULL},
        '_set_clause() for column = NULL (literal)' );
}

{
    my $q = Fey::SQL->new_update();
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             Fey::Literal->new_from_scalar('string'),
           );

    is( $q->_set_clause($dbh),
        q{SET "username" = 'string'},
        '_set_clause() for column = string (literal)' );
}

{
    my $q = Fey::SQL->new_update();
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             Fey::Literal->new_from_scalar(42),
           );

    is( $q->_set_clause($dbh),
        q{SET "username" = 42},
        '_set_clause() for column = number (literal)' );
}

{
    my $q = Fey::SQL->new_update();
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             Fey::Literal::Function->new( 'NOW' ),
           );

    is( $q->_set_clause($dbh),
        q{SET "username" = NOW()},
        '_set_clause() for column = function (literal)' );
}

{
    my $q = Fey::SQL->new_update();
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             Fey::Literal::Term->new( 'thingy' ),
           );

    is( $q->_set_clause($dbh),
        q{SET "username" = thingy},
        '_set_clause() for column = term (literal)' );
}

{
    my $q = Fey::SQL->new_update();
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'),
             Fey::Literal::Term->new( 'thingy' ),
           );

    is( $q->_set_clause($dbh),
        q{SET "username" = thingy},
        '_set_clause() for column = term (literal)' );
}

{
    my $q = Fey::SQL->new_update( auto_placeholders => 0 );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'), 'hello' );
    $q->where( $s->table('User')->column('user_id'), '=', 10 );
    $q->order_by( $s->table('User')->column('user_id') );
    $q->limit(10);

    is( $q->sql($dbh),
        q{UPDATE "User" SET "username" = 'hello' WHERE "User"."user_id" = 10 ORDER BY "User"."user_id" LIMIT 10},
        'update sql with where clause, order by, and limit' );
}

{
    my $q = Fey::SQL->new_update( auto_placeholders => 0 );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('email'), undef );

    is( $q->_set_clause($dbh),
        q{SET "email" = NULL},
        'set a column to NULL with placeholders off' );
}


{
    my $q = Fey::SQL->new_update();
    $q->update( $s->table('User'), $s->table('Group') );
    $q->set( $s->table('User')->column('username'), $s->table('Group')->column('name') );

    is( $q->_set_clause($dbh), q{SET "User"."username" = "Group"."name"},
        '_set_clause() for multi-table update' );
}

{
    my $q = Fey::SQL->new_update();
    $q->update( $s->table('User') );
    eval { $q->set() };

    like( $@, qr/list of paired/,
          'set() called with no parameters' );
}

{
    my $q = Fey::SQL->new_update();
    $q->update( $s->table('User') );
    eval { $q->set( $s->table('User')->column('username') ) };

    like( $@, qr/list of paired/,
          'set() called with one parameter' );
}

{
    package Num;

    use overload '0+' => sub { ${ $_[0] } };

    sub new
    {
        my $num = $_[1];
        return bless \$num, __PACKAGE__;
    }
}

{
    my $q = Fey::SQL->new_update( auto_placeholders => 1 );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('user_id'), Num->new(42) );

    is( $q->_set_clause($dbh), q{SET "user_id" = ?},
        '_set_clause() for one column with overloaded object and auto placeholders' );
    is_deeply( [ $q->bind_params() ], [ 42 ],
               'bind params with overloaded object' );
}


{
    my $q = Fey::SQL->new_update( auto_placeholders => 0 );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('user_id'), Num->new(42) );

    is( $q->_set_clause($dbh), q{SET "user_id" = 42},
        '_set_clause() for one column with overloaded object, no placeholders' );
}

{
    package Str;

    use overload q{""} => sub { ${ $_[0] } };

    sub new
    {
        my $str = $_[1];
        return bless \$str, __PACKAGE__;
    }
}

{
    my $q = Fey::SQL->new_update( auto_placeholders => 1 );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'), Str->new('Bubba') );

    is( $q->_set_clause($dbh), q{SET "username" = ?},
        '_set_clause() for one column with overloaded object and auto placeholders' );
    is_deeply( [ $q->bind_params() ], [ 'Bubba' ],
               'bind params with overloaded object' );
}


{
    my $q = Fey::SQL->new_update( auto_placeholders => 0 );
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'), Str->new('Bubba') );

    is( $q->_set_clause($dbh), q{SET "username" = 'Bubba'},
        '_set_clause() for one column with overloaded object, no placeholders' );
}
