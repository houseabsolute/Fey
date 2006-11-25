package Q::Literal::Number;

use strict;
use warnings;

use base 'Q::Literal';
__PACKAGE__->mk_ro_accessors
    ( qw( number ) );

use Class::Trait ( 'Q::Trait::Selectable' );
use Class::Trait ( 'Q::Trait::Comparable' );

use Q::Validate
    qw( validate_pos
        SCALAR_TYPE
      );


{
    my $spec = (SCALAR_TYPE);
    sub new
    {
        my $class = shift;
        my ($num) = validate_pos( @_, $spec );

        return bless { number => $num }, $class;
    }
}

sub type { 'number' }

sub sql_for_select  { $_[0]->number() }

sub sql_for_compare { $_[0]->number() }


1;

__END__
