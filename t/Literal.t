use strict;
use warnings;

use Test::More tests => 5;


use_ok('Q::Literal');


{
    my $fake = Q::FakeDBI->new();

    isa_ok( $fake, 'DBI' );
    ok( ! $fake->isa('Foo'), 'FakeDBI is not a Foo' );

    is( $fake->quote('foo'), q{"foo"}, 'FakeDBI->quote foo' );
    is( $fake->quote(q{"blah"}), q{"""blah"""}, 'FakeDBI->quote "blah"' );
}
