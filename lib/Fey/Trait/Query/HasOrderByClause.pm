package Fey::Trait::Query::HasOrderByClause;

use strict;
use warnings;

use Class::Trait 'base';

use Fey::Validate
    qw( validate_pos
        SCALAR
        OBJECT
      );

use Scalar::Util qw( blessed );


{
    my $spec = { type      => SCALAR|OBJECT,
                 callbacks =>
                 { 'is orderable or sort direction' =>
                   sub { return 1
                             if ! blessed $_[0] && $_[0] =~ /^(?:asc|desc)$/i;
                         return 1 if
                             (    blessed $_[0]
                               && $_[0]->can('is_orderable')
                               && $_[0]->is_orderable() ); },
                 },
               };

    sub order_by
    {
        my $self = shift;

        my $count = @_ ? @_ : 1;
        my (@by) = validate_pos( @_, ($spec) x $count );

        push @{ $self->{order_by} }, @by;
    }
}

sub _order_by_clause
{
    my $self = shift;

    return unless $self->{order_by};

    my $sql = 'ORDER BY ';

    for my $elt ( @{ $self->{order_by} } )
    {
        if ( ! blessed $elt )
        {
            $sql .= q{ } . uc $elt;
        }
        else
        {
            $sql .= ', ' if $elt != $self->{order_by}[0];
            $sql .= $elt->sql_or_alias( $self->quoter() );
        }
    }

    return $sql;
}


1;

__END__
