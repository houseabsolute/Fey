package Q::Loader::DBI;

use strict;
use warnings;

use Q::Validate qw( validate DBI_TYPE );

use Q::Schema;
use Q::Table;
use Q::Column;


{
    my $spec = { dbh  => DBI_TYPE };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        return bless \%p, $class;
    }
}

sub make_schema
{
    my $self = shift;

    for my $name ( $self->_table_names() )
    {
        my $table = Q::Table->new( name => $name );
    }
}
