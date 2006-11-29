package Q::Literal::Term;

use strict;
use warnings;

use base 'Q::Literal';
__PACKAGE__->mk_ro_accessors
    ( qw( term ) );

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
        my $class  = shift;
        my ($term) = validate_pos( @_, $spec );

        return bless { term => $term }, $class;
    }
}

sub sql_for_select  { $_[0]->term() }

*sql_for_compare = \&sql_for_select;
*sql_for_function_arg = \&sql_for_select;


1;

__END__
