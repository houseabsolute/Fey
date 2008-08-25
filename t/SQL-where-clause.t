use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More tests => 36;

use Fey::Placeholder;
use Fey::SQL;


my $s = Fey::Test->mock_test_schema_with_fks();
my $dbh = Fey::Test->mock_dbh();

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    eval { $q->where() };
    like( $@, qr/0 parameters/,
          'where() without any parameters is an error' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('user_id'), '=', 1 );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" = 1},
        'simple comparison - col = literal' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where
        ( $s->table('User')->column('user_id')->alias( alias_name => 'alias' ),
          '=', 1 );

    is( $q->_where_clause($dbh), q{WHERE "alias" = 1},
        'simple comparison - col alias = literal' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('username'), 'LIKE',
               '%foo%' );

    is( $q->_where_clause($dbh), q{WHERE "User"."username" LIKE '%foo%'},
        'simple comparison - col LIKE literal' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( 1, '=', $s->table('User')->column('user_id') );

    is( $q->_where_clause($dbh), q{WHERE 1 = "User"."user_id"},
        'simple comparison - literal = col' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('user_id'), '=', $s->table('User')->column('user_id') );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" = "User"."user_id"},
        'simple comparison - col = col' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('user_id'), 'IN', 1, 2, 3 );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" IN (1, 2, 3)},
        'simple comparison - IN' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('user_id'), 'NOT IN', 1, 2, 3 );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" NOT IN (1, 2, 3)},
        'simple comparison - IN' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('user_id'), '=',
               Fey::Placeholder->new() );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" = ?},
        'simple comparison - col = placeholder' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    my $sub = Fey::SQL->new_select( auto_placeholders => 0 )->select();
    $sub->select( $s->table('User')->column('user_id') );
    $sub->from( $s->table('User') );

    $q->where( $s->table('User')->column('user_id'), 'IN', $sub );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" IN (( SELECT "User"."user_id" FROM "User" ))},
        'comparison with subselect' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('user_id'), '=', undef );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" IS NULL},
        'undef in comparison (=)' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('user_id'), '!=', undef );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" IS NOT NULL},
        'undef in comparison (!=)' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('user_id'), 'BETWEEN', 1, 5 );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" BETWEEN 1 AND 5},
        'simple comparison - BETWEEN' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('user_id'), '=', 1 );
    $q->where( $s->table('User')->column('user_id'), '=', 2 );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" = 1 AND "User"."user_id" = 2},
        'multiple clauses with implicit AN' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('user_id'), '=', 1 );
    $q->where( 'or' );
    $q->where( $s->table('User')->column('user_id'), '=', 2 );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" = 1 OR "User"."user_id" = 2},
        'multiple clauses with OR' );
}


{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( '(' );
    $q->where( $s->table('User')->column('user_id'), '=', 2 );
    $q->where( ')' );

    is( $q->_where_clause($dbh), q{WHERE ( "User"."user_id" = 2 )},
        'subgroup in where clause' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('username'), '=', 'Bob' );
    $q->where( '(' );
    $q->where( $s->table('User')->column('username'), '=', 'Jill' );
    $q->where( ')' );

    is( $q->_where_clause($dbh), q{WHERE "User"."username" = 'Bob' AND ( "User"."username" = 'Jill' )},
        'comparison followed directly by a subgroup' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( '(' );
    $q->where( $s->table('User')->column('username'), '=', 'Jill' );
    $q->where( ')' );
    $q->where( $s->table('User')->column('username'), '=', 'Bob' );

    is( $q->_where_clause($dbh), q{WHERE ( "User"."username" = 'Jill' ) AND "User"."username" = 'Bob'},
        'subgroup followed directly by a comparison' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('username'), '=', 'Bob' );
    $q->where( 'or' );
    $q->where( '(' );
    $q->where( $s->table('User')->column('username'), '=', 'Jill' );
    $q->where( ')' );

    is( $q->_where_clause($dbh), q{WHERE "User"."username" = 'Bob' OR ( "User"."username" = 'Jill' )},
        'where clause joined to a subgroup with OR' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('user_id'), '=', 2 )
      ->and  ( $s->table('User')->column('username'), '=', 'bob' );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" = 2 AND "User"."username" = 'bob'},
        'where() and and() methods' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    eval { $q->where( $s->table('User')->column('user_id'), '=', 1, 2 ) };
    like( $@, qr/more than one right-hand side/,
          'error when passing more than one RHS with =' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    my $sub = Fey::SQL->new_select( auto_placeholders => 0 )->select();
    $sub->select( $s->table('User')->column('user_id') );
    $sub->from( $s->table('User') );

    eval { $q->where( $s->table('User')->column('user_id'), 'LIKE', $sub ) };
    like( $@, qr/use a subselect on the right-hand side/,
          'error when passing subselect with LIKE' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    eval { $q->where( $s->table('User')->column('user_id'), 'BETWEEN', 1 ) };
    like( $@, qr/requires two arguments/,
          'error when passing one RHS with BETWEEN' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    eval { $q->where( 'totally bogus' ) };
    like( $@, qr/cannot pass one argument to where/i,
          'error when passing one arg to where' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 1 )->select();

    $q->where( $s->table('User')->column('user_id'), '=', undef );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" IS NULL},
        'undef in comparison (=) with auto placeholders' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('user_id'), '=', Fey::Placeholder->new() );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" = ?},
        'explicit placeholder object in comparison (=)' );
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
    my $q = Fey::SQL->new_select( auto_placeholders => 1 )->select();

    $q->where( $s->table('User')->column('user_id'), '=', Num->new(2) );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" = ?},
        'overloaded object in comparison (=) with auto placeholders' );

    is( ( $q->bind_params() )[0], 2,
               q{bind_params() contains overloaded object's value} );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('user_id'), '=', Num->new(2) );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" = 2},
        'overloaded object in comparison (=) without auto placeholders' );
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
    my $q = Fey::SQL->new_select( auto_placeholders => 1 )->select();

    $q->where( $s->table('User')->column('user_id'), '=', Str->new('two') );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" = ?},
        'overloaded object in comparison (=) with auto placeholders' );
    is_deeply( [ $q->bind_params() ], [ 'two' ],
               q{bind_params() contains overloaded object's value} );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    $q->where( $s->table('User')->column('user_id'), '=', Str->new('two') );

    is( $q->_where_clause($dbh), q{WHERE "User"."user_id" = 'two'},
        'overloaded object in comparison (=) without auto placeholders' );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();

    eval { $q->where( $s->table('User')->column('user_id'), '=', bless {}, 'Foo' ) };
    like( $@, qr/\QCannot pass an object as part of a where clause comparison unless that object does Fey::Role::Comparable or is overloaded/,
          'get expected error when passing an unacceptable object as part of a comparison' );
}

SKIP:
{
    skip 'These tests require DateTime.pm and DateTime::Format::MySQL', 3
        unless eval { require DateTime; require DateTime::Format::MySQL; 1 };

    my $dt = DateTime->new( year      => 2008,
                            month     => 2,
                            day       => 24,
                            hour      => 12,
                            minute    => 30,
                            second    => 47,
                            time_zone => 'UTC',
                            formatter => DateTime::Format::MySQL->new(),
                          );

    my $q = Fey::SQL->new_select( auto_placeholders => 1 )->select();
    $q->where( $s->table('User')->column('username'), '=', $dt );

    is( $q->_where_clause($dbh), q{WHERE "User"."username" = ?},
        'overloaded DateTime object in comparison (=) with auto placeholders' );
    is_deeply( [ $q->bind_params() ], [ '2008-02-24 12:30:47' ],
               q{bind_params() contains overloaded object's value} );

    $q = Fey::SQL->new_select( auto_placeholders => 0 )->select();
    $q->where( $s->table('User')->column('username'), '=', $dt );

    is( $q->_where_clause($dbh), q{WHERE "User"."username" = '2008-02-24 12:30:47'},
        'overloaded DateTime object in comparison (=) without auto placeholders' );
}
