package Fey::Role::HasAliasName;

use strict;
use warnings;

our $VERSION = '0.34';

use MooseX::Role::Parameterized;

parameter 'generated_alias_prefix' =>
    ( isa      => 'Str',
      required => 1,
    );

parameter 'sql_needs_parens' =>
    ( isa     => 'Bool',
      default => 0,
    );

has 'alias_name' =>
    ( is     => 'rw',
      isa    => 'Str',
      writer => 'set_alias_name',
    );

requires 'sql';

sub sql_with_alias
{
    $_[0]->_make_alias()
        unless $_[0]->alias_name();

    my $sql = $_[0]->_sql_for_alias( $_[1] );

    $sql .= ' AS ';
    $sql .= $_[1]->quote_identifier( $_[0]->alias_name() );

    return $sql;
};

sub sql_or_alias
{
    return $_[1]->quote_identifier( $_[0]->alias_name() )
        if $_[0]->alias_name();

    return $_[0]->sql( $_[1] );
};


role
{
    my $p = shift;

    my $parens = $p->sql_needs_parens();

    method _sql_for_alias => sub
    {
        my $sql = $_[0]->sql( $_[1] );
        $sql = "( $sql )" if $parens;
        return $sql;
    };

    my $prefix = $p->generated_alias_prefix();
    my $num = 0;

    method '_make_alias' => sub
    {
        my $self = shift;
        $self->set_alias_name( $prefix . $num++ );
    };

};

no MooseX::Role::Parameterized;

1;

__END__

=head1 NAME

Fey::Role::HasAliasName - A role for objects that bring an alias with them

=head1 SYNOPSIS

  package My::Thing;

  use Moose;
  with 'Fey::Role::HasAliasName'
      => { generated_alias_prefix => 'THING' };

=head1 DESCRIPTION

This role adds an C<alias_name> attribute to objects, as well as some
methods for making use of that alias.

=head1 PARAMETERS

=head2 generated_alias_prefix

The prefix that generated aliases will have, e.g. C<LITERAL>,
C<FUNCTION>, etc. Required.

=head2 sql_needs_parens

If true, C<sql_with_alias()> will wrap the output of C<sql()> when
generating its own output. Default is false.

=head1 METHODS

=head2 $obj->alias_name()

Returns the current alias name, if any.

=head2 $obj->set_alias_name()

  $obj->set_alias_name('my object');

Sets the current alias name.

=head2 $obj->sql_with_alias()

=head2 $obj->sql_or_alias()

Returns the appropriate SQL snippet.  C<sql_with_alias> will generate
an alias if one has not been set (using C<generated_alias_prefix>,
above).

=head1 AUTHOR

Hans Dieter Pearcey <hdp.cpan.fey@weftsoar.net>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
