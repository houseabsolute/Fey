package Fey::SQL::Fragment::Where::Boolean;

use strict;
use warnings;

use Fey::Validate
    qw( validate_pos SCALAR_TYPE );


{
    my $spec = ( SCALAR_TYPE( regex => qr/^(?:and|or)$/i ) );
    sub new
    {
        my $class = shift;
        my ($op)  = validate_pos( @_, $spec );

        return bless \$op, $class;
    }
}

sub sql
{
    return uc ${ $_[0] };
}


1;

__END__

=head1 NAME

Fey::SQL::Fragment::Where::Boolean - Represents an AND or OR in a WHERE clause

=head1 DESCRIPTION

This class represents a subselect an AND or OR in a WHERE clause.

It is intended solely for internal use in L<Fey::SQL> objects, and as
such is not intended for public use.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
