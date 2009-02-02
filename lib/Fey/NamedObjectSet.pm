package Fey::NamedObjectSet;

use strict;
use warnings;

use List::AllUtils qw( all pairwise );

use Fey::Types;
use MooseX::Params::Validate qw( pos_validated_list );


sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->add(@_) if @_;

    return $self;
}

sub add
{
    my $self    = shift;

    my $count = @_ ? @_ : 1;

    $self->{ $_->name() } = $_
        for pos_validated_list( \@_,
                                ( ( { does => 'Fey::Role::Named' } ) x $count ),
                                MX_PARAMS_VALIDATE_NO_CACHE => 1,
                              );

    return;
}

sub delete
{
    my $self = shift;

    my $count = @_ ? @_ : 1;

    delete $self->{ $_->name() }
        for pos_validated_list( \@_,
                                ( ( { does => 'Fey::Role::Named' } ) x $count ),
                                MX_PARAMS_VALIDATE_NO_CACHE => 1,
                              );

    return;
}

sub object
{
    my $self   = shift;
    my ($name) = pos_validated_list( \@_, { isa => 'Str' } );

    return $self->{$name};
}

sub objects
{
    my $self = shift;

    my @names =
        pos_validated_list( \@_,
                            ( ( { isa => 'Str' } ) x scalar @_ ),
                            MX_PARAMS_VALIDATE_NO_CACHE => 1,
                          );

    return @names ? @{ $self }{ grep { exists $self->{$_} } @names } : values %{ $self };
}

sub is_same_as
{
    my $self  = shift;
    my $other = shift;

    my @self_names  = sort keys %{ $self };
    my @other_names = sort keys %{ $other };

    return 0 unless @self_names == @other_names;

    return all { $_ } pairwise { $a eq $b } @self_names, @other_names;
}

1;

=head1 NAME

Fey::NamedObjectSet - Holds a set of named objects

=head1 SYNOPSIS

  my $set = Fey::NamedObjectSet->new( $name_col, $size_col );

=head1 DESCRIPTION

This class represents a set of named objects, such as tables or
columns. You can look up objects in the set by name, or simply
retrieve all of the objects at once.

It exists to simplify Fey's internals, since named sets of objects are
quite common in SQL.

=head1 METHODS

This class provides the following methods:

=head2 Fey::NamedObjectSet->new(@objects)

This method returns a new C<Fey::NamedObjectSet> object. Any objects
passed to this method are added to the set as it is created. Each
object passed must implement a C<name()> method, which is expected to
return a unique name for that object.

=head2 $set->add(@objects)

Adds one or more named objects to the set.

=head2 $set->delete(@objects)

This method accepts one or more objects and removes them from the set,
if they are part of it.

=head2 $set->object($name)

Given a name, this method returns the corresponding object.

=head2 $set->objects(@names)

When given a list of names as an argument, this method returns the
named objects in the order specified, if they exist in the set. If not
given any arguments it returns all of the objects in th set.

=head2 $set->is_same_as($other_set)

Given a C<Fey::NamedObjectSet>, this method indicates whether or not
the two sets are the same.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
