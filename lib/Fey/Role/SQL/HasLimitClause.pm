package Fey::Role::SQL::HasLimitClause;

use strict;
use warnings;

use Fey::Validate
    qw( validate_pos
        POS_INTEGER_TYPE
        POS_OR_ZERO_INTEGER_TYPE
      );

use Scalar::Util qw( blessed );

use Moose::Role;


{
    my @spec = ( POS_INTEGER_TYPE, POS_OR_ZERO_INTEGER_TYPE( optional => 1 ) );
    sub limit
    {
        my $self = shift;
        my @limit = validate_pos( @_, @spec );

        $self->{limit}{number} = $limit[0];
        $self->{limit}{offset} = $limit[1];

        return $self;
    }
}

sub _limit_clause
{
    my $self = shift;

    return unless $self->{limit}{number};

    my $sql = 'LIMIT ' . $self->{limit}{number};
    $sql .= ' OFFSET ' . $self->{limit}{offset}
        if $self->{limit}{offset};

    return $sql;
}

no Moose::Role;

1;

__END__

=head1 NAME

Fey::Role::SQL::HasLimitClause - A role for queries which can include a LIMIT clause

=head1 SYNOPSIS

  use MooseX::StrictConstructor;

  with 'Fey::Role::SQL::HasLimitClause';

=head1 DESCRIPTION

Classes which do this role represent a query which can include a
C<LIMIT> clause.

=head1 METHODS

This role provides the following methods:

=head2 $query->limit()

See the L<Fey::SQL section on LIMIT Clauses|Fey::SQL/LIMIT Clauses>
for more details.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
