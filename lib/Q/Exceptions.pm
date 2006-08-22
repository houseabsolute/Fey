package Q::Exceptions;

use strict;
use warnings;

my %E;
BEGIN
{
    %E = ( 'Q::Exception' =>
           { description =>
             'Generic exception within the Alzabo API.  Should only be used as a base class.',
             alias => 'exception',
           },

           'Q::Exception::ObjectState' =>
           { description =>
             'You called a method on an object which its current state does not allow',
             isa => 'Q::Exception',
             alias => 'object_state_error',
           },

           'Q::Exception::Params' =>
           { description => 'An exception generated when there is an error in the parameters passed in a method of function call',
             isa => 'Q::Exception',
             alias => 'param_error',
           },

           'Q::Exception::VirtualMethod' =>
           { description =>
             'Indicates that the method called must be subclassed in the appropriate class',
             isa    => 'Q::Exception',
             alias  => 'virtual_method',
           },
         );
}

use Exception::Class (%E);

Q::Exception->Trace(1);

use base 'Exporter';

our @EXPORT_OK = map { $_->{alias} || () } values %E;


1;

__END__
