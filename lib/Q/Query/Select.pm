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
                 { 'table or column' =>
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

        $self->{select}{ $_->id() } = $_
            for @s;

        return $self;
    }
}

sub distinct { $_[0]->{distinct} = 1 }

sub _start_clause
{
    my $self = shift;

    my @select;
    for my $elt ( map { $_->can('columns')
                        ? sort { $a->name() cmp $b->name() } $_->columns()
                        : $_ }
                  map { $self->{select}{$_} }
                  sort keys %{ $self->{select} } )
    {
        if ( $elt->isa('Q::Column') )
        {
            push @select,
                ( join $self->{_name_sep},
                  map { $_->has_alias()
                        ? $_ . ' AS ' . $_->alias_name()
                        : $_ }
                  map { $self->{_quote} . $_->name() . $self->{_quote} }
                  $elt, $elt->table(),
                );
        }
        else
        {
            push @select, $elt->as_string;
        }
    }
}



1;

__END__
