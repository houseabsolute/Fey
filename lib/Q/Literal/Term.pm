package Q::Literal::Term;

use strict;
use warnings;

use base 'Q::Literal';
__PACKAGE__->mk_ro_accessors
    ( qw( term ) );

use Q::Validate
    qw( validate_pos
        SCALAR_TYPE
      );


{
    my $spec = (SCALAR_TYPE);
    sub new
    {
        my $class  = shift;
        my ($term) = validate_pos( @_, $spec );

        return bless { term => $term }, $class;
    }
}

sub type { 'term' }


1;

__END__
