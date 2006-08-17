package Q::Column;

use strict;
use warnings;

use base 'Q::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( name type generic_type length precision is_nullable ) );

use Q::Exceptions qw(param_error);
use Q::Validate
    qw( validate SCALAR_TYPE BOOLEAN_TYPE
        POS_INTEGER_TYPE POS_OR_ZERO_INTEGER_TYPE );


{
    my $gen_type_re =
        qr/text|blob|number|integer|float|date|datetime|other/;

    my $spec =
        { name         => SCALAR_TYPE,
          generic_type => SCALAR_TYPE( regex => $gen_type_re ),
          type         => SCALAR_TYPE,
          length       => POS_INTEGER_TYPE( optional => 1 ),
          precision    => POS_OR_ZERO_INTEGER_TYPE( optional => 1,
                                                    depends => [ 'length' ] ),
          is_nullable  => BOOLEAN_TYPE( default  => 0 ),
        };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $self = bless \%p, $class;

        return $self;
    }
}


1;

__END__
