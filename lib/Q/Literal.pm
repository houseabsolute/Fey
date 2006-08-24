package Q::Literal;

use strict;
use warnings;

use Q::Literal::Function;
use Q::Literal::Number;
use Q::Literal::String;
use Q::Literal::Term;


sub function
{
    shift;
    return Q::Literal::Function->new(@_);
}

sub number
{
    shift;
    return Q::Literal::Number->new(@_);
}

sub string
{
    shift;
    return Q::Literal::String->new(@_);
}

sub term
{
    shift;
    return Q::Literal::Term->new(@_);
}


1;

__END__
