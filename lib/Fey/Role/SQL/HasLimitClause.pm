package Fey::Role::SQL::HasLimitClause;

use strict;
use warnings;

use Scalar::Util qw( blessed );

use Moose::Role;
use MooseX::Params::Validate qw( pos_validated_list );

has '_limit' =>
    ( is        => 'rw',
      writer    => '_set_limit',
      predicate => '_has_limit',
    );

has '_offset' =>
    ( is        => 'rw',
      writer    => '_set_offset',
      predicate => '_has_offset',
    );


sub limit
{
    my $self = shift;
    my ( $limit, $offset ) =
        pos_validated_list( \@_,
                            { isa      => 'Fey::Types::PosInteger|Undef' },
                            { isa      => 'Fey::Types::PosOrZeroInteger',
                              optional => 1,
                            },
                          );

    $self->_set_limit($limit)
        if defined $limit;
    $self->_set_offset($offset)
        if defined $offset;

    return $self;
}

sub limit_clause
{
    my $self = shift;

    return unless $self->_has_limit() || $self->_has_offset();

    my $sql = '';

    $sql .= 'LIMIT ' . $self->_limit()
        if $self->_has_limit();
    $sql .= q{ }
        if $self->_has_limit() && $self->_has_offset();
    $sql .= 'OFFSET ' . $self->_offset()
        if $self->_has_offset();

    return $sql;
}

no Moose::Role;

1;

__END__

=head1 NAME

Fey::Role::SQL::HasLimitClause - A role for queries which can include a LIMIT clause

=head1 SYNOPSIS

  use Moose;

  with 'Fey::Role::SQL::HasLimitClause';

=head1 DESCRIPTION

Classes which do this role represent a query which can include a
C<LIMIT> clause.

=head1 METHODS

This role provides the following methods:

=head2 $query->limit()

See the L<Fey::SQL section on LIMIT Clauses|Fey::SQL/LIMIT Clauses>
for more details.

=head2 $query->limit_clause()

Returns the C<LIMIT> clause portion of the SQL statement as a string.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
