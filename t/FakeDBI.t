use strict;
use warnings;

use Test::More tests => 4;
use Fey::FakeDBI;


{
    ok( Fey::FakeDBI->isa('DBI::db'), 'FakeDBI isa DBI::db' );
    ok( ! Fey::FakeDBI->isa('Foo'), 'FakeDBI is not a Foo' );

    is( Fey::FakeDBI->quote('foo'), q{"foo"}, 'FakeDBI->quote foo' );
    is( Fey::FakeDBI->quote(q{"blah"}), q{"""blah"""}, 'FakeDBI->quote "blah"' );
}
