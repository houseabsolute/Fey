package Fey::Role::Aliasable;

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

    method 'alias' => sub
    {
        my $self = shift;
        my %p = @_ == 1 ? ( $p->name_param() => $_[0] ) : @_;

        return $p->alias_class->new( $p->self_param() => $self, %p );
    };
};

no MooseX::Role::Parameterized;

1;
