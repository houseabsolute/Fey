package Fey::Role::Cloneable;

use strict;
use warnings;

use Moose::Role;
use Moose::Util ();

sub clone {
    my $self = shift;
    
    my $meta = Moose::Util::find_meta( $self );

    # XXX breaking the MOP; we should pass everything to clone_object, but
    # almost none of these are Moose attributes yet.  once they are, we should
    # let clone_object handle this instead.

    my $clone = $meta->clone_object( $self );
    %{$clone} = (
        %$clone,
        $self->CLONEARGS_ALL,
        @_,
    );
    return $clone;
}

sub CLONEARGS { () }

sub CLONEARGS_ALL {
    my $self = shift;
    my %param;
    for my $method (
        reverse Moose::Util::find_meta($self)
          ->find_all_methods_by_name('CLONEARGS')
        ) {
        %param = (%param, $method->{code}->execute($self));
    }
    return %param;
}

1;

__END__

=head1 NAME

Fey::Role::Cloneable - A role for objects that can be cloned

=head1 SYNOPSIS

  with 'Fey::Role::Cloneable';

  sub CLONEARGS {
      my $self = shift;
      return (some_array_attribute => [ @{ $self->some_array_attribute } ]);
  }

=head1 DESCRIPTION

Classes which do this role represent objects that either are likely to need a
convenient C<clone> method or need special handling when cloned.

=head1 METHODS

This role provides the following methods:

=head2 $object->clone()

Return a sufficiently deep copy of the object that any changes to the clone
will not affect the original.

See L<Class::MOP::Class/clone_object> for more details.

=head2 CLONEARGS_ALL

=head2 CLONEARGS

Each class that needs to make a deep copy of an attribute when cloning should
return a hash from this method, as in the L</SYNOPSIS>.  C<clone> calls
C<CLONEARGS_ALL>, which accumulates results from each class in the inheritance
tree, from least-derived to most-derived classes.

=head1 AUTHOR

Hans Dieter Pearcey, <hdp@weftsoar.net>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
