package Q::Literal::String;

use strict;
use warnings;

use base 'Q::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( string ) );

use Q::Validate
    qw( validate_pos
        SCALAR_TYPE
        QUERY_TYPE
      );


{
    my $spec = (SCALAR_TYPE);
    sub new
    {
        my $class    = shift;
        my ($string) = validate_pos( @_, $spec );

        return bless { string => $string }, $class;
    }
}

sub type { 'string' }


1;

__END__
