package Fey::SQL::Fragment::SubSelect;

use strict;
use warnings;

use Fey::FakeDBI;

use constant SELECT     => 0;
use constant ALIAS_NAME => 1;

sub new
{
    my $class  = shift;
    my $select = shift;

    return bless [ $select ], $class;
}

sub id
{
    return $_[0]->sql( 'Fey::FakeDBI' );
}

sub sql_with_alias
{
    return
        (   $_[0]->sql( $_[1] )
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

sub sql { '( ' . $_[0][SELECT]->sql( $_[1] ) . ' )' }

sub sql_or_alias
{
    # XXX - I'm not sure that this case is actually possible. A
    # subselect only gets an alias if it's used in the FROM clause. If
    # that's the case, then it should not be re-used elsewhere.
    return $_[1]->quote_identifier( $_[0]->[ALIAS_NAME] )
        if $_[0]->[ALIAS_NAME];

    return $_[0]->sql( $_[1] );
}

sub bind_params
{
    return $_[0][SELECT]->bind_params();
}

1;

__END__

=head1 NAME

Fey::SQL::Fragment::SubSelect - Represents a subselect

=head1 DESCRIPTION

This class represents a subselect.

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
