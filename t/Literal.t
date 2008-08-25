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
    package Num;

    use overload '0+' => sub { ${ $_[0] } };

    sub new
    {
        my $num = $_[1];
        return bless \$num, __PACKAGE__;
    }
}

{
    my $lit = Fey::Literal->new_from_scalar( Num->new(42) );
    isa_ok( $lit, 'Fey::Literal::Number' );
    is( $lit->number(), 42, 'value is 42' );
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
    my $lit = Fey::Literal->new_from_scalar( Str->new('test') );
    isa_ok( $lit, 'Fey::Literal::String' );
    is( $lit->string(), 'test', 'value is test' );
}
