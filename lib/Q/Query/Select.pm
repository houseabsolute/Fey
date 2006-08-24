package Q::Query::Select;

use strict;
use warnings;

use base 'Q::Query';

__PACKAGE__->mk_ro_accessors
    ( qw( is_distinct ) );

use Q::Exceptions qw( object_state_error );
use Q::Validate
    qw( validate_pos
        SCALAR
        OBJECT
      );

use Q::Literal;
use Scalar::Util qw( blessed );


{
    my $spec = { type      => SCALAR|OBJECT,
                 callbacks =>
                 { 'table, alias, literal, column, or scalar' =>
                   sub {    ! blessed $_[0]
                         || $_[0]->isa('Q::Table')
                         || $_[0]->isa('Q::Literal')
                         || (    $_[0]->isa('Q::Column')
                              && $_[0]->table() ) },
                 },
               };
    sub select
    {
        my $self = shift;
        my @s    = validate_pos( @_, ($spec) x @_ );

        for my $elt ( map { $_->can('columns')
                            ? sort { $a->name() cmp $b->name() } $_->columns()
                           : $_ }
                      map { blessed $_ ? $_ : Q::Literal::Term->new($_) }
                      @s )
        {
            my $key = $elt->can('id') ? $elt->id() : $self->format_literal($elt);
            $self->{select}{$key} = $elt;
        }

        return $self;
    }
}

sub distinct
{
    $_[0]->{is_distinct} = 1;

    return $_[0];
}

sub sql
{
    my $self = shift;

    return
        ( join ' ',
          $self->_select_clause(),
          $self->_from_clause(),
          $self->_where_clause(),
          $self->_group_by_clause(),
          $self->_order_by_clause(),
          $self->_limit_clause(),
        );
}

sub _select_clause
{
    my $self = shift;

    my $sql = 'SELECT ';
    $sql .= 'DISTINCT ' if $self->is_distinct();
    $sql .=
        ( join ', ',
          map { $self->_format_column_or_literal( $self->{select}{$_} ) }
          sort
          keys %{ $self->{select} }
        );

    return $sql;
}


1;

__END__
