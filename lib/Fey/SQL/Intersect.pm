package Fey::SQL::Intersect;

use strict;
use warnings;

our $VERSION = '0.33';

use Moose;

with 'Fey::Role::SetOperation' => { keyword => 'INTERSECT' };

with 'Fey::Role::SQL::Cloneable';

no Moose;

1;

__END__

=head1 NAME

Fey::SQL::Intersect - Represents an INTERSECT operation

=head1 SYNOPSIS

  my $intersect = Fey::SQL->new_intersect;

  $intersect->intersect( Fey::SQL->new_select->select(...),
                         Fey::SQL->new_select->select(...),
                         Fey::SQL->new_select->select(...),
                         ...
                       );

  $intersect->order_by( $part_name, 'DESC' );
  $intersect->limit(10);

  print $intersect->sql($dbh);

=head1 DESCRIPTION

This class represents an INTERSECT set operator.

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
