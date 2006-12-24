package Q::Test::SQLite;

use strict;
use warnings;

use Test::More;

BEGIN
{
    unless ( eval { require DBD::mysql; 1 } )
    {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        plan skip_all => 'These tests require DBD::mysql';
    }

    unless ( $ENV{Q_MAINTAINER_TEST_MYSQL} || -d '.svn' )
    {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        plan skip_all =>
            'These tests are only run if the Q_MAINTAINER_TEST_MYSQL'
            . ' env var is true, or if being run from an SVN checkout dir.';
    }
}

use DBI;
use File::Spec;
use File::Temp ();


{
    my $DBH;
    sub dbh
    {
        my $class = shift;

        return $DBH if $DBH;

        my $dbh =
            DBI->connect
                ( 'dbi:mysql:', '', '', { PrintError => 0, RaiseError => 1 } );

        $dbh->func( 'dropdb', 'test_Q', 'admin' );

        # The dropdb command apparently disconnects the handle.
        $dbh =
            DBI->connect
                ( 'dbi:mysql:', '', '', { PrintError => 0, RaiseError => 1 } );

        $dbh->func( 'createdb', 'test_Q', 'admin' )
            or die $dbh->errstr();

        $dbh =
            DBI->connect
                ( 'dbi:mysql:test_Q', '', '', { PrintError => 0, RaiseError => 1 } );

        $dbh->do( 'SET sql_mode = ANSI' );

        $class->_run_ddl($dbh);

        return $dbh;
    }
}

sub _run_ddl
{
    my $class = shift;
    my $dbh   = shift;

    for my $ddl ( $class->_sql() )
    {
        $dbh->do($ddl);
    }
}

sub _sql
{
    return
        ( <<'EOF',
CREATE TABLE User (
    user_id   integer  not null  auto_increment,
    username  text     not null,
    email     text     null,
    PRIMARY KEY (user_id)
) TYPE=INNODB
EOF
          <<'EOF',
CREATE TABLE "Group" (
    group_id   integer  not null  auto_increment,
    name       text     not null,
    PRIMARY KEY (group_id)
) TYPE=INNODB
EOF
          <<'EOF',
CREATE TABLE UserGroup (
    user_id   integer  not null,
    group_id  integer  not null,
    PRIMARY KEY (user_id, group_id),
    FOREIGN KEY (user_id)  REFERENCES User    (user_id),
    FOREIGN KEY (group_id) REFERENCES "Group" (group_id)
) TYPE=INNODB
EOF
          <<'EOF',
CREATE TABLE Message (
    message_id    integer       not null  auto_increment,
    quality       decimal(5,2)  not null  default 2.3,
    message       varchar(255)  not null  default 'Some message text',
    message_date  timestamp     not null  default CURRENT_TIMESTAMP,
    PRIMARY KEY (message_id)
) TYPE=INNODB
EOF
          <<'EOF',
CREATE VIEW TestView
         AS SELECT user_id FROM User
EOF
        );
}


1;

__END__
