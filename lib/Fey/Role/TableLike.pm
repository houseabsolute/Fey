package Fey::Role::TableLike;

use strict;
use warnings;
use namespace::autoclean;

use Moose::Role;

with 'Fey::Role::Joinable';

requires 'sql_for_select_clause';

1;

# ABSTRACT: A role for things that are like a table

__END__

=head1 SYNOPSIS

  use Moose;

  with 'Fey::Role::TableLike';

=head1 DESCRIPTION

This role has no methods or attributes of its own. It does consume the
L<Fey::Role::Joinable> role.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=cut
