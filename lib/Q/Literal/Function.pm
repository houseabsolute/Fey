package Q::Literal::Function;

use strict;
use warnings;

use base 'Q::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( function ) );

use Q::Validate
    qw( validate_pos
        SCALAR_TYPE
      );

use Scalar::Util qw( blessed );


{
    sub new
    {
        my $class = shift;
        my $func  = shift;

        my $self = bless { function => $func };
        $self->{args} =
            [ map { blessed $_ ? $_ : Q::Literal::Term->new($_) } @_ ];

        return $self;
    }
}

sub args { @{ $_[0]->{args} } }

sub type { 'function' }


1;

__END__
