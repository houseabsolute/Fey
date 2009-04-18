package Fey::SQL::Union;

use strict;
use warnings;

use Moose;

with 'Fey::Role::SetOperation' => { keyword => 'UNION' };

with 'Fey::Role::SQL::Cloneable';

no Moose;

1;

__END__

=head1 NAME

Fey::SQL::Union - Represents a UNION operation

=head1 SYNOPSIS

  my $union = Fey::SQL->new_union;

  $union->union( Fey::SQL->new_select->select(...),
                 Fey::SQL->new_select->select(...),
                 Fey::SQL->new_select->select(...),
                 ...
               );

  $union->order_by( $part_name, 'DESC' );
  $union->limit(10);

  print $union->sql($dbh);

=head1 DESCRIPTION

This class represents a UNION set operator.

=head1 METHODS

See L<Fey::Role::SetOperation> for all methods.

=head1 ROLES

=over 4

=item * L<Fey::Role::SetOperation>

=item * L<Fey::Role::SQL::Cloneable>

=back

=head1 AUTHOR

Hans Dieter Pearcey, <hdp.cpan.fey@weftsoar.net>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
