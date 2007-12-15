package Fey::Role;

use Moose::Role ();

{
    # This is a nasty hack because when M::M::R sees a conflicting
    # role (two roles sharing the same method) it simply adds that
    # role to the list of required methods for the importing class,
    # but in this case it makes no sense, since I want ColumnLike to
    # basically replace the various is_* methods from Selectable,
    # Comparable, etc.

    package # hide from PAUSE
        Moose::Meta::Role;

    my $original;
    BEGIN { $original = Moose::Meta::Role->can('_apply_methods') }

    no warnings 'redefine';
sub _apply_methods {
    my ($self, $other) = @_;

    return $self->$original($other)
        unless $other->name() =~ /^Fey::/;

    foreach my $method_name ($self->get_method_list) {
        # it if it has one already
        if ($other->has_method($method_name) &&
            # and if they are not the same thing ...
            $other->get_method($method_name)->body != $self->get_method($method_name)->body) {
            # see if we are composing into a role
            if ($other->isa('Moose::Meta::Role')) {
                # NOTE:
                # we have to remove the method from our 
                # role, if this is being called from combine()
                # which means the meta is an anon class
                # this *may* cause problems later, but it 
                # is probably fairly safe to assume that 
                # anon classes will only be used internally
                # or by people who know what they are doing
                $other->Moose::Meta::Class::remove_method($method_name)
                    if $other->name =~ /__COMPOSITE_ROLE_SANDBOX__/;
            }
            else {
                next;
            }
        }
        else {
            # add it, although it could be overriden 
            $other->alias_method(
                $method_name,
                $self->get_method($method_name)
            );
        }
    }
}
}
