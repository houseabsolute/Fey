package Q::Literal::Null;

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

my $Null = 'NULL';
sub new
{
    my $class  = shift;

    return bless \$Null, $class;
}

sub sql  { 'NULL' }

sub sql_with_alias { goto &sql }

sub sql_or_alias { goto &sql }


1;

__END__
