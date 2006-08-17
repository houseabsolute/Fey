package Q::Schema;

use strict;
use warnings;

use base 'Q::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( name dbh ) );

use Q::Exceptions qw(param_error);
use Q::Validate
    qw( validate validate_pos
        SCALAR_TYPE ARRAYREF_TYPE
        TABLE_TYPE FK_TYPE DBI_TYPE );

use Q::Query;
use Q::Table;


{
    my $spec = { dbh  => DBI_TYPE };
    sub from_dbh
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $loader = Q::Loader->new( dbh => $p{dbh} );

        return $loader->make_schema();
    }
}

{
    my $spec = { name => SCALAR_TYPE };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $self =
            bless { %p,
                    tables => {},
                  }, $class;

        return $self;
    }
}

{
    my $spec = (TABLE_TYPE);
    sub add_table
    {
        my $self  = shift;
        my ($table) = validate_pos( @_, $spec );

        my $name = $table->name();
        param_error "The schema already contains a table named $name."
            if $self->table($name);

        $self->{tables}{$name} = $table;
        $table->_set_schema($self);

        return $self;
    }
}

{
    my $spec = (SCALAR_TYPE);
    sub table
    {
        my $self = shift;
        my ($name) = validate_pos( @_, $spec );

        return unless $self->{tables}{$name};
        return $self->{tables}{$name};
    }
}

sub tables
{
    my $self = shift;

    return values %{ $self->{tables} };
}

{
    my $spec = (TABLE_TYPE);
    sub remove_table
    {
        my $self = shift;
        my ($table) = validate_pos( @_, $spec );

        my $name = $table->name();

        $table->_set_schema(undef);

        return $self;
    }
}

{
    my $spec = (DBI_TYPE);
    sub set_dbh
    {
        my $self  = shift;
        my ($dbh) = validate_pos( @_, $spec );

        $self->{dbh} = $dbh;

        return $self;
    }
}

{
    my $spec = (FK_TYPE);
    sub add_foreign_key
    {
        my $self = shift;
        my ($fk)  = validate_pos( @_, $spec );


    }
}

sub query { Q::Query->new( dbh => $_[0]->dbh() ) }


1;

__END__
