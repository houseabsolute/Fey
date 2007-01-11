use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More tests => 16;

use Fey::Query;

my $s = Fey::Test->mock_test_schema();

my $size =
    Fey::Column->new( name        => 'size',
                    type        => 'text',
                    is_nullable => 1,
                  );
$s->table('User')->add_column($size);


{
    my $q = Fey::Query->new( dbh => $s->dbh() )->insert();

    eval { $q->into() };
    like( $@, qr/1 was expected/,
          'into() without any parameters fails' );

}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->insert();

    $q->into( $s->table('User')->column('username') );

    is( $q->_insert_clause(), q{INSERT INTO "User"},
        '_insert_clause() for User table' );
    is( $q->_into_clause(), q{("username")},
        '_into_clause with one column' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->insert();

    $q->into( $s->table('User')->column('user_id'),
              $s->table('User')->column('username') );

    is( $q->_insert_clause(), q{INSERT INTO "User"},
        '_insert_clause() for User table' );
    is( $q->_into_clause(), q{("user_id", "username")},
        '_into_clause with two columns' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->insert();

    $q->into( $s->table('User')->column('user_id'),
              $s->table('User')->column('username') );

    eval { $q->values( not_a_column => 1,
                       user_id => 2,
                     ) };
    like( $@, qr/not_a_column/,
          'cannot pass key to values() that is not a column name' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->insert();

    $q->into( $s->table('User')->column('user_id'),
              $s->table('User')->column('username') );

    eval { $q->values( username => 'bob' ) };
    like( $@, qr/Mandatory parameter 'user_id'/,
          'columns without a default are required when calling values()' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->insert();

    $q->into( $s->table('User')->column('user_id'),
              $s->table('User')->column('username') );

    eval { $q->values( user_id => 1, username => undef ) };
    like( $@, qr/was an 'undef'/,
          'cannot pass undef for non-nullable column' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->insert();

    $q->into( $s->table('User')->column('size') );

    $q->values( size => 'big' );
    is( $q->_values_clause(), q{VALUES ('big')},
        '_values_clause() for string as value' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->insert();

    $q->into( $s->table('User')->column('size') );

    $q->values( size => undef );
    is( $q->_values_clause(), q{VALUES (NULL)},
        '_values_clause() for null as value' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->insert();

    $q->into( $s->table('User')->column('size') );

    my $func = Fey::Literal->function('NOW');
    $q->values( size => $func );
    is( $q->_values_clause(), q{VALUES (NOW())},
        '_values_clause() for function as value' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->insert();

    $q->into( $s->table('User')->column('size') );

    my $term = Fey::Literal->term('term test');
    $q->values( size => $term );
    is( $q->_values_clause(), q{VALUES (term test)},
        '_values_clause() for term as value' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->insert();

    $q->into( $s->table('User')->column('size') );

    $q->values( size => Fey::Placeholder->new() );
    is( $q->_values_clause(), q{VALUES (?)},
        '_values_clause() for placeholder as value' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->insert();

    $q->into( $s->table('User')->column('size') );

    $q->values( size => Fey::Placeholder->new() );
    is( $q->_values_clause(), q{VALUES (?)},
        '_values_clause() for placeholder as value' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->insert();

    $q->into( $s->table('User')->column('size') );

    $q->values( size => 1 );
    $q->values( size => 2 );
    is( $q->_values_clause(), q{VALUES (1),(2)},
        '_values_clause() for extended insert (multiple sets of values)' );
}

{
    my $q = Fey::Query->new( dbh => $s->dbh() )->insert();

    $q->into( $s->table('User')->column('size') );

    $q->values( size => 1 );
    is( $q->sql(), q{INSERT INTO "User" ("size") VALUES (1)},
        'sql() for full insert clause' );
}
