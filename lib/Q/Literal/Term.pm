package Q::Literal::Term;

use strict;
use warnings;

use base 'Q::Literal';
__PACKAGE__->mk_ro_accessors
    ( qw( term ) );

use Class::Trait ( 'Q::Trait::Selectable' );
use Class::Trait ( 'Q::Trait::Comparable' );
use Class::Trait ( 'Q::Trait::Groupable' );
use Class::Trait ( 'Q::Trait::Orderable' );

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

sub sql  { $_[0]->term() }

sub sql_with_alias { goto &sql }

sub sql_or_alias { goto &sql }


1;

__END__
