package Q::Query::Insert;

use strict;
use warnings;

use base 'Q::Query';

use Q::Exceptions qw( object_state_error param_error );
use Q::Validate
    qw( validate_pos
        SCALAR
        OBJECT
        TABLE_TYPE
      );

use Scalar::Util qw( blessed );


sub insert { return $_[0] }

{
    my @spec = { type => OBJECT,
                 callbacks =>
                 { 'is a table or column' =>
                   sub { ( $_[0]->isa('Q::Table') || $_[0]->isa('Q::Column') )
                         && ! $_[0]->is_alias() }
                 },
               };
    sub into
    {
        my $self = shift;
        my ($t)  = validate_pos( @_, @spec );

        $self->{table} = $t;

        return $self;
    }
}

{
    my $spec = { type      => SCALAR|OBJECT,
                 callbacks =>
                 { 'is a literal, placeholder, or scalar' =>
                    sub { (    ! blessed $_[0]
                            || $_[0]->isa('Q::Placeholder')
                            || $_[0]->isa('Q::Literal')
                          ) },
                 }
               };
    sub values
    {
        my $self = shift;
        my @vals = validate_pos( @_, ($spec) x scalar $self->{table}->columns );
    }
}



1;

__END__
