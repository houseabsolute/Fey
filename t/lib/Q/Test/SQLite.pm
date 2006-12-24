package Q::Test::SQLite;

use strict;
use warnings;

use Test::More;

BEGIN
{
    unless ( eval { require DBD::SQLite; 1 } )
    {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        plan skip_all => 'These tests require DBD::SQLite';
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

        my $dir = File::Temp::tempdir( CLEANUP => 1 );
        my $file = File::Spec->catfile( $dir, 'qtest.sqlite' );

        my $dbh =
            DBI->connect
                ( "dbi:SQLite:dbname=$file", '', '', { RaiseError => 1 } );

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
)
EOF
          <<'EOF',
CREATE TABLE "Group" (
    group_id   integer  not null  primary key autoincrement,
    name       text     not null
)
EOF
          <<'EOF',
CREATE TABLE UserGroup (
    user_id   integer  not null,
    group_id  integer  not null,
    PRIMARY KEY (user_id, group_id)
)
EOF
          <<'EOF',
CREATE TABLE Message (
    message_id  integer     not null  primary key autoincrement,
    quality     real(5,2)   not null  default 2.3,
    message     text        not null  default 'Some message text'
)
EOF
          <<'EOF',
CREATE VIEW TestView
         AS SELECT user_id FROM User
EOF
        );
}


1;

__END__
