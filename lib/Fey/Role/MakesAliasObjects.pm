package Fey::Role::MakesAliasObjects;

use strict;
use warnings;

use MooseX::Role::Parameterized;

parameter 'alias_class' =>
    ( is       => 'ro',
      isa      => 'ClassName',
      required => 1,
    );

parameter 'self_param' =>
    ( is       => 'ro',
      isa      => 'Str',
      required => 1,
    );

parameter 'name_param' =>
    ( is       => 'ro',
      isa      => 'Str',
      default  => 'alias_name',
    );

role
{
    my $p = shift;

    my $alias_class = $p->alias_class;
    my $self_param  = $p->self_param;
    my $name_param  = $p->name_param;

    method 'alias' => sub
    {
        my $self = shift;
        my %p = @_ == 1 ? ( $name_param => $_[0] ) : @_;

        return $alias_class->new( $self_param => $self, %p );
    };
};

no MooseX::Role::Parameterized;

1;
