package Fey::NamedObjectSet;

use strict;
use warnings;

use List::MoreUtils qw( all pairwise );

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

