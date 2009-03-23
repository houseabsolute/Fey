use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More tests => 27;

use Fey::Placeholder;
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
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    eval { $q->into() };
    like( $@, qr/1 was expected/,
          'into() without any parameters fails' );

}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $q->into( $s->table('User')->column('username') );

    is( $q->insert_clause($dbh), q{INSERT INTO "User"},
        'insert_clause() for User table' );
    is( $q->columns_clause($dbh), q{("username")},
        'columns_clause with one column' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $q->into( $s->table('User') );

    is( $q->insert_clause($dbh), q{INSERT INTO "User"},
        'insert_clause() for User table' );
    is( $q->columns_clause($dbh), q{("email", "user_id", "size", "username")},
        'columns_clause with one table' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $q->into( $s->table('User')->column('user_id'),
              $s->table('User')->column('username') );

    is( $q->insert_clause($dbh), q{INSERT INTO "User"},
        'insert_clause() for User table' );
    is( $q->columns_clause($dbh), q{("user_id", "username")},
        'columns_clause with two columns' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $q->into( $s->table('User')->column('user_id'),
              $s->table('User')->column('username') );

    eval { $q->values( not_a_column => 1,
                       user_id => 2,
                     ) };
    like( $@, qr/not_a_column/,
          'cannot pass key to values() that is not a column name' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $q->into( $s->table('User')->column('user_id'),
              $s->table('User')->column('username') );

    eval { $q->values( username => 'bob' ) };
    like( $@, qr/Mandatory parameter 'user_id'/,
          'columns without a default are required when calling values()' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $q->into( $s->table('User')->column('user_id'),
              $s->table('User')->column('username') );

    eval { $q->values( user_id => 1, username => undef ) };
    like( $@, qr/\QThe 'username' parameter (undef)/,
          'cannot pass undef for non-nullable column' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $q->into( $s->table('User')->column('size') );

    $q->values( size => 'big' );
    is( $q->values_clause($dbh), q{VALUES ('big')},
        'values_clause() for string as value' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $q->into( $s->table('User')->column('size') );

    $q->values( size => undef );
    is( $q->values_clause($dbh), q{VALUES (NULL)},
        'values_clause() for null as value' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 1 )->insert();

    $q->into( $s->table('User')->column('size') );

    $q->values( size => undef );
    is( $q->values_clause($dbh), q{VALUES (NULL)},
        'values_clause() for null as value with auto placeholders' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $q->into( $s->table('User')->column('size') );

    my $func = Fey::Literal::Function->new('NOW');
    $q->values( size => $func );
    is( $q->values_clause($dbh), q{VALUES (NOW())},
        'values_clause() for function as value' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $q->into( $s->table('User')->column('size') );

    my $term = Fey::Literal::Term->new('term test');
    $q->values( size => $term );
    is( $q->values_clause($dbh), q{VALUES (term test)},
        'values_clause() for term as value' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $q->into( $s->table('User')->column('size') );

    $q->values( size => Fey::Placeholder->new() );
    is( $q->values_clause($dbh), q{VALUES (?)},
        'values_clause() for placeholder as value' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $q->into( $s->table('User')->column('size') );

    $q->values( size => Fey::Placeholder->new() );
    is( $q->values_clause($dbh), q{VALUES (?)},
        'values_clause() for placeholder as value' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $q->into( $s->table('User')->column('size') );

    $q->values( size => 1 );
    $q->values( size => 2 );
    is( $q->values_clause($dbh), q{VALUES (1),(2)},
        'values_clause() for extended insert (multiple sets of values)' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $q->into( $s->table('User')->column('size') );

    $q->values( size => 1 );
    is( $q->sql($dbh), q{INSERT INTO "User" ("size") VALUES (1)},
        'sql() for full insert clause' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 1 )->insert();

    $q->into( $s->table('User')->column('user_id'),
              $s->table('User')->column('username') );

    $q->values( user_id => 42, username => 'Bubba' );

    is( $q->columns_clause($dbh), q{("user_id", "username")},
        'insert clause has columns in expected order' );
    is( $q->values_clause($dbh), q{VALUES (?, ?)},
        'values_clause() for two columns column with auto placeholders' );
    is_deeply( [ $q->bind_params() ], [ 42, 'Bubba' ],
               'bind params are in the right order' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 1 )->insert();

    $q->into( $s->table('User')->column('username'),
              $s->table('User')->column('user_id') );

    $q->values( user_id => 42, username => 'Bubba' );

    is( $q->columns_clause($dbh), q{("username", "user_id")},
        'columns clause has columns in expected order' );
    is_deeply( [ $q->bind_params() ], [ 'Bubba', 42 ],
               'bind params are in the right order' );
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
    package Str;

    use overload q{""} => sub { ${ $_[0] } };

    sub new
    {
        my $str = $_[1];
        return bless \$str, __PACKAGE__;
    }
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 1 )->insert();

    $q->into( $s->table('User')->column('user_id'),
              $s->table('User')->column('username') );

    $q->values( user_id => Num->new(42), username => Str->new('Bubba') );

    is( $q->values_clause($dbh), q{VALUES (?, ?)},
        'values_clause() for two columns column with overloaded objects and auto placeholders' );
    is_deeply( [ $q->bind_params() ], [ 42, 'Bubba' ],
               'bind params with overloaded object' );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $q->into( $s->table('User')->column('user_id'),
              $s->table('User')->column('username') );

    $q->values( user_id => Num->new(42), username => Str->new('Bubba') );

    is( $q->values_clause($dbh), q{VALUES (42, 'Bubba')},
        'values_clause() for two columns column with overloaded object, no placeholders' );
}
