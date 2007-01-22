package Fey::SQL::Fragment::Where::Boolean;

use strict;
use warnings;

use Fey::Validate
    qw( validate_pos SCALAR_TYPE );


{
    my $spec = ( SCALAR_TYPE( regex => qr/^(?:and|or)$/i ) );
    sub new
    {
        my $class = shift;
        my ($op)  = validate_pos( @_, $spec );

        return bless \$op, $class;
    }
}

sub sql
{
    return uc ${ $_[0] };
}


1;

__END__
