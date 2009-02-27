package Fey::SQL::Fragment::SubSelect;

use strict;
use warnings;

use Fey::FakeDBI;

use Moose;
use Fey::Types;

with 'Fey::Role::Comparable';

has '_select' =>
    ( is       => 'ro',
      isa      => 'Fey.Type.SubSelectArg',
      required => 1,
      init_arg => 'select',
    );

has 'alias' =>
    ( is        => 'ro',
      isa       => 'Str',
      lazy      => 1,
      builder   => '_build_alias',
      predicate => '_has_alias',
    );

sub id
{
    my $self = shift;

    return $self->sql( 'Fey::FakeDBI' );
}

sub sql_with_alias
{
    my $self = shift;
    my $dbh  = shift;

    return
        (   $self->sql( $dbh )
          . ' AS '
          . $self->alias()
        );
}

{
    my $Number = 0;
    sub _build_alias
    {
        return 'SUBSELECT' . $Number++;
    }
}

sub sql
{
    my $self = shift;
    my $dbh  = shift;

    return '( ' . $self->_select()->sql( $dbh ) . ' )';
}

sub sql_or_alias
{
    my $self = shift;
    my $dbh  = shift;

    # XXX - I'm not sure that this case is actually possible. A
    # subselect only gets an alias if it's used in the FROM clause. If
    # that's the case, then it should not be re-used elsewhere.
    return $dbh->quote_identifier( $self->alias() )
        if $self->_has_alias();

    return $self->sql( $dbh );
}

sub bind_params
{
    my $self = shift;

    return $self->_select()->bind_params();
}

no Moose;

__PACKAGE__->meta()->make_immutable();

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

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
