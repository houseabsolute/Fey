package Fey::SQL::Base;

use strict;
use warnings;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_ro_accessors
    ( qw( dbh quoter ) );

use Fey::Validate
    qw( validate
        DBI_TYPE
      );


{
    my $spec = { dbh => DBI_TYPE };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $quoter = Fey::Quoter->new( dbh => $p{dbh} );

        return bless { %p,
                       quoter => $quoter,
                     }, $class;
    }
}


1;

__END__

=head1 NAME

Fey::SQL::Select - Base class for Fey::SQL::* classes

=head1 SYNOPSIS

  package Fey::SQL::Select;

  use base 'Fey::SQL::Base';

=head1 DESCRIPTION

This class provides a simple constructor and some attributes for all
types of queries.

=head1 METHODS

This class provides the following methods:

=head2 Fey::SQL::Base->new()

The constructor expects a single named argument, "dbh", which must be
a valid DBI handle.

=head2 $query->dbh()

Returns the DBI handle passed to the constructor.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
