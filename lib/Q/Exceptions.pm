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

           'Q::Exception::Params' =>
           { description => 'An exception generated when there is an error in the parameters passed in a method of function call',
             isa => 'Q::Exception',
             alias => 'param_error',
           },
         );
}

use Exception::Class (%E);

Q::Exception->Trace(1);

use base 'Exporter';

our @EXPORT_OK = map { $_->{alias} || () } values %E;


1;

__END__
