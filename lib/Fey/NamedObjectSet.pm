package Fey::NamedObjectSet;

use strict;
use warnings;

use Moose;

use Fey::Validate
    qw( validate_pos SCALAR_TYPE NAMED_OBJECT_TYPE );


sub new
{
    my $class = shift;

    return bless {}, $class;
}

sub add
{
    my $self    = shift;

    my $count = @_ ? @_ : 1;
    validate_pos( @_, ( NAMED_OBJECT_TYPE ) x $count );

    $self->{ $_->name() } = $_ for @_;
}

sub delete
{
    my $self = shift;

    my $count = @_ ? @_ : 1;
    validate_pos( @_, ( NAMED_OBJECT_TYPE ) x $count );

    delete $self->{ $_->name() } for @_;
}

sub object
{
    my $self   = shift;
    my ($name) = validate_pos( @_, SCALAR_TYPE );

    return $self->{$name};
}

sub objects
{
    my $self = shift;

    validate_pos( @_, ( SCALAR_TYPE ) x @_ );

    return @_ ? @{ $self }{ grep { exists $self->{$_} } @_ } : values %{ $self };
}


1;

