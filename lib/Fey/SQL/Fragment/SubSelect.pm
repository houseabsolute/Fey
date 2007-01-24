package Fey::SQL::Fragment::SubSelect;

use strict;
use warnings;

use constant SELECT     => 0;
use constant ALIAS_NAME => 1;

sub new
{
    my $class  = shift;
    my $select = shift;

    return bless [ $select ], $class;
}

sub id { goto &sql }

sub sql_with_alias
{
    return
        (   $_[0]->sql()
          . ' AS '
          . $_[0]->_make_alias()
        );
}

{
    my $Number = 0;
    sub _make_alias
    {
        $_[0]->[ALIAS_NAME] = 'SUBSELECT' . $Number++;
    }
}

sub sql { '( ' . $_[0][SELECT]->sql() . ' )' }

sub sql_or_alias
{
    return $_[1]->quote_identifier( $_[0]->[ALIAS_NAME] )
        if $_[0]->[ALIAS_NAME];

    return $_[0]->sql( $_[1] );
}


1;

__END__

=head1 NAME

Fey::SQL::Fragment::Subselect - Represents a subselect

=head1 DESCRIPTOIN

This class represents a subselect.

It is intended solely for internal use in L<Fey::SQL> objects, and as
such is not intended for public use.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
