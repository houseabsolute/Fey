package Q::Query::Fragment::SubSelect;

use strict;
use warnings;

use Class::Trait ( 'Q::Trait::Joinable' );

use constant SELECT  => 0;


my $Counter = 0;
sub new
{
    my $class  = shift;
    my $select = shift;

    return bless [ $select ], $class;
}

sub id { $_[0][SELECT]->sql() }

sub sql_for_join
{
    return
        (   $_[0]->_sql()
          . ' AS '
          . $_[0]->_make_alias()
        );
}

sub _sql { '( ' . $_[0][SELECT]->sql() . ' )' }

sub _make_alias
{
    return 'SUBSELECT' . $Counter++;
}

sub sql_for_compare
{
    return $_[0]->_sql();
}


1;

__END__
