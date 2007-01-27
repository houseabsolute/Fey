package Fey::SQL::Base;

use strict;
use warnings;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_ro_accessors
    ( qw( dbh quoter ) );

use Fey::Validate
    qw( validate
        DBI_TYPE
      );


{
    my $spec = { dbh => DBI_TYPE };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $quoter = Fey::Quoter->new( dbh => $p{dbh} );

        return bless { %p,
                       quoter => $quoter,
                     }, $class;
    }
}


1;

__END__
