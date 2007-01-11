package Fey::Literal::Number;

use strict;
use warnings;

use base 'Fey::Literal';
__PACKAGE__->mk_ro_accessors
    ( qw( number ) );

use Class::Trait ( 'Fey::Trait::Selectable' );
use Class::Trait ( 'Fey::Trait::Comparable' );

use Fey::Validate
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

sub sql  { $_[0]->number() }

sub sql_with_alias { goto &sql }

sub sql_or_alias { goto &sql }


1;

__END__
