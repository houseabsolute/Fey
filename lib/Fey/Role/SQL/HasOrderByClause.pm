package Fey::Role::SQL::HasOrderByClause;

use strict;
use warnings;

use Moose::Role;

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

        return $self;
    }
}

sub _order_by_clause
{
    my $self = shift;
    my $dbh  = shift;

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
            $sql .= $elt->sql_or_alias($dbh);
        }
    }

    return $sql;
}


1;

__END__

=head1 NAME

Fey::Role::SQL::HasOrderByClause - A role for queries which can include a ORDER BY clause

=head1 SYNOPSIS

  use MooseX::StrictConstructor;

  with 'Fey::Role::SQL::HasOrderByClause';

=head1 DESCRIPTION

Classes which do this role represent a query which can include a
C<ORDER BY> clause.

=head1 METHODS

This role provides the following methods:

=head2 $query->order_by()

See the L<Fey::SQL section on ORDER BY Clauses|Fey::SQL/ORDER BY
Clauses> for more details.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
