package Fey::Literal::String;

use strict;
use warnings;

use base 'Fey::Literal';
__PACKAGE__->mk_ro_accessors
    ( qw( string ) );

use Class::Trait ( 'Fey::Trait::Selectable' );
use Class::Trait ( 'Fey::Trait::Comparable' );

use Fey::Validate
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

sub sql  { $_[1]->quote_string( $_[0]->string() ) }

sub sql_with_alias { goto &sql }

sub sql_or_alias { goto &sql }


1;

__END__