package Q::Literal::String;

use strict;
use warnings;

use base 'Q::Literal';
__PACKAGE__->mk_ro_accessors
    ( qw( string ) );

use Class::Trait ( 'Q::Trait::Selectable' );
use Class::Trait ( 'Q::Trait::Comparable' );

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

sub sql_for_select  { $_[1]->quote_string( $_[0]->string() ) }

*sql_for_compare = \&sql_for_select;
*sql_for_function_arg = \&sql_for_select;


1;

__END__
