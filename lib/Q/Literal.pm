package Q::Literal;

use strict;
use warnings;

use base 'Q::Accessor';

use Q::Literal::Function;
use Q::Literal::Null;
use Q::Literal::Number;
use Q::Literal::String;
use Q::Literal::Term;
use Q::Query::Quoter;
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
    return Q::Literal::Function->new(@_);
}

sub null
{
    return Q::Literal::Null->new();
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

{
    my $quoter = Q::Query::Quoter->new( dbh => Q::FakeDBI->new() );
    sub id
    {
        return $_[0]->sql( $quoter );
    }
}

# This package allows us to use the quoter class in id(). Even
# though they may not be quoted properly for a given DBMS, it will
# generate unique ids, and that's all that matters.

package # Hide from PAUSE
    Q::FakeDBI;


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
