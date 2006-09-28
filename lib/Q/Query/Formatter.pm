package Q::Query::Formatter;

use strict;
use warnings;

use base 'Q::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( dbh ) );

use Q::Validate
    qw( validate
        DBI_TYPE );

{
    my $spec = { dbh => DBI_TYPE };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $quote = $p{dbh}->get_info(29);
        $quote = q{"} unless defined $quote;

        # Not sure if this needs to be changed per-DBMS, and if so,
        # can it be discovered from the database handle (portably)?
        my $sep = q{.};

        return bless { %p,
                       quote => $quote,
                       sep   => $sep,
                     }, $class;
    }
}

sub format_for_select
{
    return
        (   $_[1]->isa('Q::Column')
          ? $_[0]->_fq_column_name_and_alias($_[1])
          : $_[0]->_literal_and_alias( $_[1] )
        );
}

sub _literal_and_alias
{
    my $sql = $_[0]->format_literal( $_[1] );

    my $alias = $_[0]->_alias_for_literal( $_[1] );

    return $sql . ' AS ' . $alias;
}

sub _alias_for_literal
{
    my $type = $_[1]->type();

    $_[0]->{counters}{$type} ||= 0;

    return $_[0]->{aliases}{ $_[1]->id() }
        ||= uc $type . $_[0]->{counters}{$type}++;
}

sub _lhs_for_where
{
    return $_[0]->format_literal( $_[1] )
        if $_[1]->isa('Q::Literal');

    return $_[0]->{quote} . $_[1]->alias_name() . $_[0]->{quote}
        if $_[1]->is_alias();

    return $_[0]->_fq_column_name( $_[1] );
}
*_column_or_literal_for_function_arg = \&_lhs_for_where;

sub _rhs_for_where
{
    return $_[0]->format_literal( $_[1] )
        if $_[1]->isa('Q::Literal');

    return '?'
        if $_[1]->isa('Q::Placeholder');

    return $_[1]->as_sql( $_[0], 'where' )
        if $_[1]->isa('Q::Query::Fragment::SubSelect');

    return $_[0]->{quote} . $_[1]->alias_name() . $_[0]->{quote}
        if $_[1]->is_alias();

    return $_[0]->_fq_column_name( $_[1] );
}

sub _fq_column_name
{
    my $t = $_[1]->table();

    return
        (   $_[0]->{quote}
          . $_[0]->_table_name_or_alias( $_[1]->table() )
          . $_[0]->{quote}
          . $_[0]->{sep}
          . $_[0]->{quote}
          . $_[1]->name()
          . $_[0]->{quote}
        );
}

sub _table_name_or_alias
{
    $_[1]->is_alias() ? $_[1]->alias_name() : $_[1]->name();
}

sub _fq_column_name_and_alias
{
    my $fq = $_[0]->_fq_column_name( $_[1] );

    return $fq unless $_[1]->is_alias();

    return
        ( $fq
          . ' AS '
          . $_[0]->{quote}
          . $_[1]->alias_name()
          . $_[0]->{quote}
        );
}

sub _table_name
{
    return
        (   $_[0]->{quote}
          . $_[1]->name()
          . $_[0]->{quote}
        );
}

sub _table_name_for_from
{
    my $t = $_[0]->_table_name( $_[1] );

    return $t unless $_[1]->is_alias();

    return
        ( $t
          . ' AS '
          . $_[0]->{quote}
          . $_[1]->alias_name()
          . $_[0]->{quote}
        );
}

sub format_literal
{
    my $meth = 'format_' . $_[1]->type();
    return $_[0]->$meth( $_[1] );
}

sub format_function
{
    my $self  = shift;
    my $func  = shift;
    my $alias = shift;

    my $sql = $func->function();
    $sql .= '(';

    $sql .=
        ( join ', ',
          map { $self->_column_or_literal_for_function_arg($_) }
          $func->args()
        );
    $sql .= ')';

    return $sql;
}

sub format_number
{
    return $_[1]->number();
}

sub format_string
{
    return $_[0]->dbh()->quote( $_[1]->string() );
}

sub format_term
{
    return $_[1]->term();
}


1;

__END__
