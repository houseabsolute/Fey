package Q::Query::Fragment::SubSelect;

use strict;
use warnings;

use constant SELECT     => 0;
use constant ALIAS_NAME => 1;

sub new
{
    my $class  = shift;
    my $select = shift;

    return bless [ $select ], $class;
}

sub id { goto &sql }

sub sql_with_alias
{
    return
        (   $_[0]->sql()
          . ' AS '
          . $_[0]->_make_alias()
        );
}

{
    my $Number = 0;
    sub _make_alias
    {
        $_[0]->[ALIAS_NAME] = 'SUBSELECT' . $Number++;
    }
}

sub sql { '( ' . $_[0][SELECT]->sql() . ' )' }

sub sql_or_alias
{
    return $_[1]->quote_identifier( $_[0]->[ALIAS_NAME] )
        if $_[0]->[ALIAS_NAME];

    return $_[0]->sql( $_[1] );
}


1;

__END__
