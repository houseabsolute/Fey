package Fey::Quoter;

use strict;
use warnings;

use base 'Fey::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( dbh ) );

use Fey::Validate
    qw( validate
        DBI_TYPE );

{
    my $spec = { dbh => DBI_TYPE };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $quote = $p{dbh}->get_info(29);
        $quote = q{"} unless defined $quote;

        # Not sure if this needs to be changed per-DBMS, and if so,
        # can it be discovered from the database handle (portably)?
        my $sep = q{.};

        return bless { %p,
                       quote => $quote,
                       sep   => $sep,
                     }, $class;
    }
}

sub quote_identifier
{
    return $_[0]->{quote} . $_[1] . $_[0]->{quote};
}

sub unquote_identifier
{
    my $self  = shift;
    my $ident = shift;

    $ident =~ s/^\Q$self->{quote}\E|\Q$self->{quote}\E$//g;

    return $ident;
}

sub quote_string
{
    return $_[0]->dbh()->quote( $_[1] );
}

sub join_table_and_column
{
    return $_[1] . $_[0]->{sep} . $_[2];
}


1;

__END__
