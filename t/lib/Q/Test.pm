package Q::Test;

use strict;
use warnings;

use DBI;
use File::Temp ();


sub mock_dbh
{
    return Q::Test::MockDBI->new();
}


package Q::Test::MockDBI;

sub new
{
    return bless {}, shift;
}

sub table_info
{
    return
        Q::Test::MockSTH->new
            ( { TABLE_NAME => 'User' },
              { TABLE_NAME => 'UserEmailAddress' },
            );
}

sub isa
{
    return 1 if $_[1] eq 'DBI';
}


package Q::Test::MockSTH;

sub new
{
    my $class = shift;
    my @rows = @_;

    return bless \@rows, $class;
}

sub fetchrow_hashref
{
    my $self = shift;

    return unless @$self;
    return shift @$self;
}


1;

__DATA__

CREATE TABLE User (
    user_id   INTEGER  PRIMARY KEY  AUTOINCREMENT,
    username  TEXT  NOT NULL
);

----

CREATE TABLE UserEmailAddress (
    user_id   INTEGER  NOT NULL  REFERENCES User (user_id),
    email     TEXT  NOT NULL,
    PRIMARY KEY ( user_id, email )
);
