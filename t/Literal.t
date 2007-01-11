use strict;
use warnings;

use Test::More tests => 10;
use Fey::Literal;


{
    my $lit = Fey::Literal->new_from_scalar( 4.2 );
    isa_ok( $lit, 'Fey::Literal::Number' );

    $lit = Fey::Literal->new_from_scalar(4);
    isa_ok( $lit, 'Fey::Literal::Number' );

    $lit = Fey::Literal->new_from_scalar('4');
    isa_ok( $lit, 'Fey::Literal::Number' );

    $lit = Fey::Literal->new_from_scalar('hello');
    isa_ok( $lit, 'Fey::Literal::String' );

    $lit = Fey::Literal->new_from_scalar('hello 21');
    isa_ok( $lit, 'Fey::Literal::String' );

    $lit = Fey::Literal->new_from_scalar('');
    isa_ok( $lit, 'Fey::Literal::String' );
}

{
    my $fake = Fey::FakeDBI->new();

    isa_ok( $fake, 'DBI::db' );
    ok( ! $fake->isa('Foo'), 'FakeDBI is not a Foo' );

    is( $fake->quote('foo'), q{"foo"}, 'FakeDBI->quote foo' );
    is( $fake->quote(q{"blah"}), q{"""blah"""}, 'FakeDBI->quote "blah"' );
}
