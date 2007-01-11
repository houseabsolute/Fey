package Fey::Exceptions;

use strict;
use warnings;

my %E;
BEGIN
{
    %E = ( 'Fey::Exception' =>
           { description =>
             'Generic exception within the Alzabo API.  Should only be used as a base class.',
             alias => 'exception',
           },

           'Fey::Exception::ObjectState' =>
           { description =>
             'You called a method on an object which its current state does not allow',
             isa => 'Fey::Exception',
             alias => 'object_state_error',
           },

           'Fey::Exception::Params' =>
           { description => 'An exception generated when there is an error in the parameters passed in a method of function call',
             isa => 'Fey::Exception',
             alias => 'param_error',
           },

           'Fey::Exception::VirtualMethod' =>
           { description =>
             'Indicates that the method called must be subclassed in the appropriate class',
             isa    => 'Fey::Exception',
             alias  => 'virtual_method',
           },
         );
}

use Exception::Class (%E);

Fey::Exception->Trace(1);

use base 'Exporter';

our @EXPORT_OK = map { $_->{alias} || () } values %E;


1;

__END__
