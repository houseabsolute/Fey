package Fey::Literal::Term;

use strict;
use warnings;

use base 'Fey::Literal';
__PACKAGE__->mk_ro_accessors
    ( qw( term ) );

use Class::Trait ( 'Fey::Trait::Selectable' );
use Class::Trait ( 'Fey::Trait::Comparable' );
use Class::Trait ( 'Fey::Trait::Groupable' );
use Class::Trait ( 'Fey::Trait::Orderable' );

use Fey::Validate
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

sub sql  { $_[0]->term() }

sub sql_with_alias { goto &sql }

sub sql_or_alias { goto &sql }


1;

__END__
