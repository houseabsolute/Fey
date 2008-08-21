package Fey::Table::Alias;

use strict;
use warnings;

use Fey::Exceptions qw(param_error);
use Fey::Validate
    qw( validate validate_pos
        SCALAR_TYPE
        TABLE_TYPE );

use Fey::Table;

use Moose::Policy 'MooseX::Policy::SemiAffordanceAccessor';
use MooseX::StrictConstructor;

with 'Fey::Role::Joinable';


has 'id' =>
    ( is         => 'ro',
      lazy_build => 1,
      init_arg   => undef,
    );

has 'table' =>
    ( is      => 'ro',
      isa     => 'Fey::Table',
      handles => [ 'schema', 'name' ],
    );

has 'alias_name' =>
    ( is         => 'ro',
      isa        => 'Str',
      lazy_build => 1,
    );


{
    my %Numbers;
    sub _build_alias_name
    {
        my $self = shift;

        my $name = $self->name();
        $Numbers{$name} ||= 0;

        return $name . ++$Numbers{$name};
    }
}

{
    my $spec = (SCALAR_TYPE);
    sub column
    {
        my $self = shift;
        my ($name) = validate_pos( @_, $spec );

        return $self->{columns}{$name}
            if $self->{columns}{$name};

        my $col = $self->table()->column($name)
            or return;

        my $clone = $col->_clone();
        $clone->_set_table($self);

        return $self->{columns}{$name} = $clone;
    }
}

sub columns
{
    my $self = shift;

    my @cols = @_ ? @_ : map { $_->name() } $self->table()->columns();

    return map { $self->column($_) } @cols;
}

# Making this an attribute would be a hassle since we'd need to reset
# it whenever the associated table's keys changed.
sub primary_key
{
    return [ $_[0]->columns( map { $_->name() } @{ $_[0]->table()->primary_key() } ) ];
}

sub is_alias { 1 }

sub sql_with_alias
{
    return
        (   $_[1]->quote_identifier( $_[0]->table()->name() )
          . ' AS '
          . $_[1]->quote_identifier( $_[0]->alias_name() )
        );
}

sub _build_id { $_[0]->alias_name() }

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Fey::Table::Alias - Represents an alias for a table

=head1 SYNOPSIS

  my $alias = $user_table->alias();

  my $alias = $user_table->alias( alias_name => 'User2' );

=head1 DESCRIPTION

This class represents an alias for a table. Table aliases allow you to
join the same table more than once in a query, which makes certain
types of queries simpler to express.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Table::Alias->new()

This method constructs a new C<Fey::Table::Alias> object. It takes the
following parameters:

=over 4

=item * table - required

This is the C<Fey::Table> object which we are aliasing.

=item * alias_name - optional

This should be a valid table name for your DBMS. If not provided, a
unique name is automatically created.

=back

=head2 $alias->table()

Returns the C<Fey::Table> object for which this object is an alias.

=head2 $alias->alias_name()

Returns the name for this alias.

=head2 $alias->name()

=head2 $alias->schema()

These methods work like the corresponding methods in
C<Fey::Table>. The C<name()> method returns the real table name.

=head2 $alias->column($name)

=head2 $alias->columns()

=head2 $alias->columns(@names)

=head2 $alias->primary_key()

These methods work like the corresponding methods in
C<Fey::Table>. However, the columns they return will return the alias
object when C<< $column->table() >> is called.

=head2 $alias->is_alias()

Always returns true.

=head2 $alias->sql_with_alias()

Returns the appropriate SQL snippet for the alias.

=head2 $alias->id()

Returns a unique string identifying the alias.

=head1 ROLES

This class does the C<Fey::Role::Joinable> role.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
