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

sub sql
{
    my $self = shift;

    return
        ( join ' ',
          $self->_start_clause(),
          $self->_from_clause(),
          $self->_where_clause(),
          $self->_group_by_clause(),
          $self->_order_by_clause(),
          $self->_limit_clause(),
        );
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


1;

__END__
