package Fey::Literal;

use strict;
use warnings;

use base 'Fey::Accessor';

use Fey::Literal::Function;
use Fey::Literal::Null;
use Fey::Literal::Number;
use Fey::Literal::String;
use Fey::Literal::Term;
use Fey::Quoter;
use Scalar::Util qw( looks_like_number );


sub new_from_scalar
{
    return
        (   ! defined $_[1]
          ? $_[0]->null()
          : looks_like_number( $_[1] )
          ? $_[0]->number( $_[1] )
          : $_[0]->string( $_[1] )
        );
}

sub function
{
    shift;
    return Fey::Literal::Function->new(@_);
}

sub null
{
    return Fey::Literal::Null->new();
}

sub number
{
    shift;
    return Fey::Literal::Number->new(@_);
}

sub string
{
    shift;
    return Fey::Literal::String->new(@_);
}

sub term
{
    shift;
    return Fey::Literal::Term->new(@_);
}

{
    my $quoter = Fey::Quoter->new( dbh => Fey::FakeDBI->new() );
    sub id
    {
        return $_[0]->sql( $quoter );
    }
}

# This package allows us to use the quoter class in id(). Even
# though they may not be quoted properly for a given DBMS, it will
# generate unique ids, and that's all that matters.

package # Hide from PAUSE
    Fey::FakeDBI;


sub new { bless \$_[0], $_[0] }

sub get_info
{
    return;
}

sub isa
{
    return 1 if $_[1] eq 'DBI::db';
}

sub quote
{
    my $text = $_[1];

    $text =~ s/"/""/g;
    return q{"} . $text . q{"};
}


1;

__END__
