use strict;
use warnings;

use Test::More tests => 10;
use Q::Literal;


{
    my $lit = Q::Literal->new_from_scalar( 4.2 );
    isa_ok( $lit, 'Q::Literal::Number' );

    $lit = Q::Literal->new_from_scalar(4);
    isa_ok( $lit, 'Q::Literal::Number' );

    $lit = Q::Literal->new_from_scalar('4');
    isa_ok( $lit, 'Q::Literal::Number' );

    $lit = Q::Literal->new_from_scalar('hello');
    isa_ok( $lit, 'Q::Literal::String' );

    $lit = Q::Literal->new_from_scalar('hello 21');
    isa_ok( $lit, 'Q::Literal::String' );

    $lit = Q::Literal->new_from_scalar('');
    isa_ok( $lit, 'Q::Literal::String' );
}

{
    my $fake = Q::FakeDBI->new();

    isa_ok( $fake, 'DBI' );
    ok( ! $fake->isa('Foo'), 'FakeDBI is not a Foo' );

    is( $fake->quote('foo'), q{"foo"}, 'FakeDBI->quote foo' );
    is( $fake->quote(q{"blah"}), q{"""blah"""}, 'FakeDBI->quote "blah"' );
}
