package Q::Query::Select;

use strict;
use warnings;

use base 'Q::Query';

use Q::Exceptions qw( object_state_error param_error );
use Q::Validate
    qw( validate_pos
        OBJECT
      );

{
    my $spec = { type      => OBJECT,
                 callbacks =>
                 { 'table, alias, literal, or column' =>
                   sub {    $_[0]->isa('Q::Table')
                         || $_[0]->isa('Q::Query::Literal')
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
                      @s )
        {
            $self->{select}{ $elt->id() } = $elt;
        }

        return $self;
    }
}

sub distinct { $_[0]->{distinct} = 1 }

sub _start_clause
{
    my $self = shift;

    my @select;
    for my $elt ( map { $self->{select}{$_} }
                  sort keys %{ $self->{select} } )
    {
        if ( $elt->isa('Q::Column') )
        {
            push @select, $self->_fq_column_name_with_alias($elt);
        }
        else
        {
            push @select, $elt->as_string;
        }
    }

    return 'SELECT ' . join ', ', @select;
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


1;

__END__
