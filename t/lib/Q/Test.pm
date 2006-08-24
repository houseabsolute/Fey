package Q::Test;

use strict;
use warnings;

use DBI;
use File::Temp ();

BEGIN
{
    # This freaking module is reporting warnings from overload.pm,
    # which is calling can() as a method. Test::MockObject insists on
    # loading it for some reason.
    $INC{'UNIVERSAL/can.pm'} = 1;
}

use Test::MockObject;


sub mock_test_schema
{
    require Q::Schema;

    my $schema = Q::Schema->new( name => 'Test' );

    $schema->add_table( _user_table() );

    $schema->add_table( _group_table() );

    $schema->add_table( _user_group_table() );

    $schema->add_table( _message_table() );

    $schema->set_dbh( mock_dbh() );
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

sub mock_dbh
{
    my $mock = Test::MockObject->new();

    $mock->set_isa('DBI');

    $mock->mock( 'get_info', \&_mock_get_info );

    $mock->mock( 'quote', \&_mock_quote );

    return $mock;
}

{
    my %Info = ( 29 => q{"},
                 41 => q{.},
               );
    sub _mock_get_info
    {
        my $self = shift;
        my $num  = shift;

        return $Info{$num}
    }
}

sub _mock_quote
{
    my $self = shift;
    my $str  = shift;

    my $q = q{'};

    $str =~ s/$q/$q$q/g;

    return "$q$str$q";
}


1;
