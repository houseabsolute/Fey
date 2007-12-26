use strict;
use warnings;

use Test::More tests => 6;
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
