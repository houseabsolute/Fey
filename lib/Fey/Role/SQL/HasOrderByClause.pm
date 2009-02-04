package Fey::Role::SQL::HasOrderByClause;

use strict;
use warnings;

use Fey::Types;
use Scalar::Util qw( blessed );

use Moose::Role;
use MooseX::AttributeHelpers;
use MooseX::Params::Validate qw( pos_validated_list );

has '_order_by' =>
    ( metaclass => 'Collection::Array',
      is        => 'ro',
      isa       => 'ArrayRef',
      default   => sub { [] },
      provides  => { push  => '_add_order_by_elements',
                     empty => '_has_order_by_elements',
                   },
      init_arg  => undef,
    );


sub order_by
{
    my $self = shift;

    my $count = @_ ? @_ : 1;
    my (@by) =
        pos_validated_list( \@_,
                            ( ( { isa => 'Fey.Type.OrderByElement' } ) x $count ),
                            MX_PARAMS_VALIDATE_NO_CACHE => 1,
                          );

    $self->_add_order_by_elements(@by);

    return $self;
}

sub order_by_clause
{
    my $self = shift;
    my $dbh  = shift;

    return unless $self->_has_order_by_elements();

    my $sql = 'ORDER BY ';

    my @elt = @{ $self->_order_by() };

    for my $elt (@elt)
    {
        if ( ! blessed $elt )
        {
            $sql .= q{ } . uc $elt;
        }
        else
        {
            $sql .= ', ' if $elt != $elt[0];
            $sql .= $elt->sql_or_alias($dbh);
        }
    }

    return $sql;
}

no Moose::Role;

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

=head2 $query->order_by_clause()

Returns the C<ORDER BY> clause portion of the SQL statement as a
string.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
