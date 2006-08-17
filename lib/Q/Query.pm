package Q::Query;

use strict;
use warnings;

use Q::Exceptions qw(param_error);
use Q::Validate
    qw( validate DBI_TYPE );


{
    my $spec = { dbh => DBI_TYPE };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        return bless \%p, $class;
    }
}

sub select
{
    
}


1;

__END__
