package Q::Query;

use strict;
use warnings;

use base 'Q::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( dbh ) );

use Q::Exceptions qw( param_error virtual_method );
use Q::Validate
    qw( validate
        OBJECT
        DBI_TYPE );

use Q::Query::Delete;
use Q::Query::Insert;
use Q::Query::Select;
use Q::Query::Update;
use Q::Query::Fragment::Where;


{
    my $spec = { dbh => DBI_TYPE };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $quote = $p{dbh}->get_info(29) || q{"};
        my $sep   = $p{dbh}->get_info(41) || q{.};

        return bless { %p,
                       _quote      => $quote,
                       _name_sep   => $sep,
                     }, $class;
    }
}

sub select
{
    my $self = shift;

    $self->_rebless('Q::Query::Select');

    return $self->select(@_);
}

sub _rebless
{
    my $self  = shift;
    my $class = shift;

    my $new = $class->new( dbh => $self->dbh() );

    %$self = %$new;

    bless $self, ref $new;
}

sub where
{
    my $self = shift;

    return $self;
}

sub _start_clause
{
    my $class = ref $_[0];
    virtual_method
        "The _start_clause() method must be overridden in the $class class.";
}

sub _from_clause
{
    return ();
}

sub _where_clause
{
    return ();
}

sub _group_by_clause
{
    return ();
}

sub _order_by_clause
{
    return ();
}

sub _limit_clause
{
    return ();
}

sub _fq_column_name
{
    my $t = $_[1]->table();

    return
        (   $_[0]->{_quote}
          . ( $t->is_alias() ? $t->alias_name() : $t->name() )
          . $_[0]->{_quote}
          . $_[0]->{_name_sep}
          . $_[0]->{_quote}
          . $_[1]->name()
          . $_[0]->{_quote}
        );
}

sub _fq_column_name_with_alias
{
    my $fq = $_[0]->_fq_column_name( $_[1] );

    return $fq unless $_[1]->is_alias();

    return
        ( $fq
          . ' AS '
          . $_[0]->{_quote}
          . $_[1]->alias_name()
          . $_[0]->{_quote}
        );
}

sub _table_name
{
    return
        (   $_[0]->{_quote}
          . $_[1]->name()
          . $_[0]->{_quote}
        );
}

sub _table_name_with_alias
{
    my $t = $_[0]->_table_name( $_[1] );

    return $t unless $_[1]->is_alias();

    return
        ( $t
          . ' AS '
          . $_[0]->{_quote}
          . $_[1]->alias_name()
          . $_[0]->{_quote}
        );
}

sub quote
{
    return $_[0]->dbh()->quote( $_[1] );
}

sub _format_column_or_literal_with_alias
{
    if ( $_[1]->isa('Q::Column') )
    {
        return $_[0]->_fq_column_name_with_alias($_[1]);
    }
    else
    {
        return $_[0]->_literal_with_alias( $_[1] );
    }
}

sub _literal_with_alias
{
    my $sql = $_[0]->format_literal( $_[1] );

    my $alias = $_[0]->_alias_for_literal( $_[1], $sql );

    return $sql . ' AS ' . $alias;
}

sub _alias_for_literal
{
    my $type = $_[1]->type();
    my $id   = $_[2];

    $_[0]->{counters}{$type} ||= 0;

    return $_[0]->{aliases}{$id} ||= uc $type . $_[0]->{counters}{$type}++;
}

sub _format_column_or_literal
{
    if ( $_[1]->isa('Q::Column') )
    {
        return $_[0]->_fq_column_name($_[1]);
    }
    else
    {
        return $_[0]->format_literal( $_[1] );
    }
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
          map { $self->_format_column_or_literal($_) }
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
    return $_[0]->quote( $_[1]->string() );
}

sub format_term
{
    return $_[1]->term();
}



1;

__END__
