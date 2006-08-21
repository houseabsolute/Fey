package Q::Test;

use strict;
use warnings;

use DBI;
use File::Temp ();


sub mock_dbh
{
    return Q::Test::MockDBI->new();
}

sub mock_test_schema
{
    require Q::Schema;

    my $schema = Q::Schema->new( name => 'Test' );

    $schema->add_table( _user_table() );

    $schema->add_table( _group_table() );

    $schema->add_table( _user_group_table() );

    $schema->add_table( _message_table() );
}

sub _user_table
{
    my $t = Q::Table->new( name => 'User' );

    my $user_id =
        Q::Column->new( name              => 'user_id',
                        type              => 'integer',
                        is_auto_increment => 1,
                      );

    my $username =
        Q::Column->new( name => 'username',
                        type => 'text',
                      );

    my $email =
        Q::Column->new( name => 'email',
                        type => 'text',
                      );

    $t->add_column($_) for $user_id, $username, $email;
    $t->set_primary_key($user_id);

    return $t;
}

sub _group_table
{
    my $t = Q::Table->new( name => 'Group' );

    my $group_id =
        Q::Column->new( name              => 'group_id',
                        type              => 'integer',
                        is_auto_increment => 1,
                      );

    my $name =
        Q::Column->new( name => 'name',
                        type => 'text',
                      );

    $t->add_column($_) for $group_id, $name;
    $t->set_primary_key($group_id);

    return $t;
}

sub _user_group_table
{
    my $t = Q::Table->new( name => 'UserGroup' );

    my $user_id =
        Q::Column->new( name => 'user_id',
                        type => 'integer',
                      );

    my $group_id =
        Q::Column->new( name => 'group_id',
                        type => 'integer',
                      );

    $t->add_column($_) for $user_id, $group_id;
    $t->set_primary_key( $user_id, $group_id );

    return $t;
}

sub _message_table
{
    my $t = Q::Table->new( name => 'Message' );

    my $message_id =
        Q::Column->new( name              => 'message_id',
                        type              => 'integer',
                        is_auto_increment => 1,
                      );

    my $message =
        Q::Column->new( name => 'message',
                        type => 'text',
                      );

    $t->add_column($_) for $message_id, $message;
    $t->set_primary_key($message_id);

    return $t;
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
