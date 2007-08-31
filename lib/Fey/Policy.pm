package Fey::Policy;

# This is all more or less copy & pasted from Moose::Policy::FollowPBP.

use constant attribute_metaclass => 'Fey::Policy::Attribute';

package Fey::Policy::Attribute;

use Moose;

extends 'Moose::Meta::Attribute';

before '_process_options' => sub
{
    my $class   = shift;
    my $name    = shift;
    my $options = shift;

    if ( exists $options->{is} &&
         ! ( exists $options->{reader} || exists $options->{writer} ) )
    {
        if ( $options->{is} eq 'ro' )
        {
            $options->{reader} = $name;
        }
        elsif ( $options->{is} eq 'rw' )
        {
            $options->{reader} = $name;
            $options->{writer} = 'set_' . $name;
        }

        delete $options->{is};
    }
};

1;
