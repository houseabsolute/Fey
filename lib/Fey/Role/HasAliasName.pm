package Fey::Role::HasAliasName;

use MooseX::Role::Parameterized;

parameter generated_alias_prefix =>
    ( isa     => 'Str',
      required => 1,
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

    my $sql = $_[0]->sql( $_[1] );

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

    my $Num = 0;

    my $prefix = $p->generated_alias_prefix;

    method '_make_alias' => sub
    {
        my $self = shift;
        $self->set_alias_name( $prefix . $Num++ );
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
  with 'Fey::Role::HasAliasName' => {
    generated_alias_prefix => 'THING',
  };

=head1 DESCRIPTION

This role is for objects that generate and store their aliases as attributes,
usually because they have no other name of their own.

=head1 PARAMETERS

=head2 generated_alias_prefix

The prefix that generated aliases will have, e.g. C<LITERAL>, C<FUNCTION>, etc.
Required.

=head1 METHODS

=head2 $obj->alias_name()

Returns the current alias name, if any.

=head2 $obj->set_alias_name()

  $obj->set_alias_name('my object');

Sets the current alias name.

=head2 $obj->sql_with_alias()

=head2 $obj->sql_or_alias()

Returns the appropriate SQL snippet.  C<sql_with_alias> will generate an alias
if one has not been set (using C<generated_alias_prefix>, above).

=head1 AUTHOR

Hans Dieter Pearcey <hdp.cpan.fey@weftsoar.net>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
