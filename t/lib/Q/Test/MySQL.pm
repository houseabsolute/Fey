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
                ( 'dbi:mysql:', '', '', { RaiseError => 1 } );

        $dbh->func( 'createdb', 'test_Q', 'admin' );

        $dbh =
            DBI->connect
                ( 'dbi:mysql:test_Q', '', '', { RaiseError => 1 } );

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
    user_id   integer  not null  primary key autoincrement,
    username  text     not null,
    email     text     null
) TYPE=INNODB
EOF
          <<'EOF',
CREATE TABLE "Group" (
    group_id   integer  not null  primary key autoincrement,
    name       text     not null
) TYPE=INNODB
EOF
          <<'EOF',
CREATE TABLE UserGroup (
    user_id   integer  not null,
    group_id  integer  not null,
    PRIMARY KEY (user_id, group_id)
) TYPE=INNODB
EOF
          <<'EOF',
CREATE TABLE Message (
    message_id  integer     not null  primary key autoincrement,
    quality     real(5,2)   not null  default 2.3,
    message     text        not null  default 'Some message text'
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
