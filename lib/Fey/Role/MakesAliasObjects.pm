package Fey::Role::MakesAliasObjects;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.42';

use Fey::Types qw( ClassName Str );

use MooseX::Role::Parameterized 0.04;

parameter 'alias_class' => (
    is       => 'ro',
    isa      => ClassName,
    required => 1,
);

parameter 'self_param' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

parameter 'name_param' => (
    is      => 'ro',
    isa     => Str,
    default => 'alias_name',
);

role {
    my $p = shift;

    my $alias_class = $p->alias_class();
    my $self_param  = $p->self_param();
    my $name_param  = $p->name_param();

    method 'alias' => sub {
        my $self = shift;
        my %p = @_ == 1 ? ( $name_param => $_[0] ) : @_;

        return $alias_class->new( $self_param => $self, %p );
    };
};

1;

# ABSTRACT: A role for objects with separate alias objects

__END__

=head1 SYNOPSIS

  package My::Thing;

  use Moose 0.90;

  with 'Fey::Role::MakesAliasObjects'
      => { alias_class => 'My::Alias',
           self_param  => 'thing',
           name_param  => 'alias_name',
         };

=head1 DESCRIPTION

This role adds a "make an alias object" method to a class. This is for
things like tables and columns, which can have aliases.

=head1 PARAMETERS

=head2 alias_class

The name of the class whose C<new()> is called by the C<alias()>
method (see below). Required.

=head2 self_param

The name of the parameter to pass C<$self> to the C<alias_class>'
C<new()> method as. Required.

=head2 name_param

The name of the parameter to C<alias()> that passing a single string
is assumed to be. Defaults to C<alias_name>.

=head1 METHODS

=head2 $obj->alias()

  my $alias = $obj->alias(alias_name => 'an_alias', %other_params);

  my $alias = $obj->alias('an_alias');

Create a new alias for this object.  If a single parameter is
provided, it is assumed to be whatever the C<name_param> parameter
specifies (see above).

=head1 BUGS

See L<Fey> for details on how to report bugs.

=cut
