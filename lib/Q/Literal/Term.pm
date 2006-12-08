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

sub sql_for_select  { $_[0]->term() }

sub sql_for_compare { goto &sql_for_select }

sub sql_for_function_arg { goto &sql_for_select }

sub sql_for_group_by     { goto &sql_for_compare }

sub sql_for_order_by     { goto &sql_for_compare }



1;

__END__
