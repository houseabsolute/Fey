package Q::Loader::SQLite;

use strict;
use warnings;

use base 'Q::Loader::DBI';

use DBD::SQLite;

unless ( defined &DBD::SQLite::db::column_info )
{
    *DBD::SQLite::db::column_info = \&_sqlite_column_info;
}

sub _sqlite_column_info {
    my($dbh, $catalog, $schema, $table, $column) = @_;

    my $sth_tables = $dbh->table_info($catalog, $schema, $table, '');

    my $row = $sth_tables->fetchrow_hashref;
    my @cols = _parse_table_sql( $row->{sqlite_sql} );

    my @names = qw( TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME
                    DATA_TYPE TYPE_NAME COLUMN_SIZE BUFFER_LENGTH
                    DECIMAL_DIGITS NUM_PREC_RADIX NULLABLE
                    REMARKS COLUMN_DEF SQL_DATA_TYPE SQL_DATETIME_SUB
                    CHAR_OCTET_LENGTH ORDINAL_POSITION IS_NULLABLE
                  );
    for my $col (@cols) {
        $col->{TABLE_NAME} = $table;

        for my $key (@names) {
            $col->{$key} = undef
                unless exists $col->{$key};
        }
    }

    my $sponge = DBI->connect("DBI:Sponge:", '','')
        or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");
    my $sth = $sponge->prepare("column_info $table", {
        rows => [ map { [ @{$_}{@names} ] } @cols ],
        NUM_OF_FIELDS => scalar @names,
        NAME => \@names,
    }) or return $dbh->DBI::set_err($sponge->err(), $sponge->errstr());
    return $sth;
}

sub _parse_table_sql {
    my($sql) = @_;

    return unless $sql;

    $sql =~ s/^\s*create\s+table\s+[^\(]+\(\s*//i;
    $sql =~ s/\s*\)\s*$//;

    my @cols;

    while ( $sql =~ /\G\s*(?!PRIMARY KEY)(\S+)\s+(\S+)\s+(.*)(?:,|$)\n?/gi ) {
        my($name, $type, $etc) = ($1, $2, $3);
        $name =~ s/^\"|\"$//g;

        my ($size, $digits) = $type =~ /\w+\((\d+)(?:,(\d+))?\)/;

        my $default  = $etc =~ /default\s+((?:'[^']+')|\S+)/ ? $1 : undef;
        my $nullable = $etc =~ /not null/ ? 0 : 1;
        my $autoinc  = $etc =~ /autoincrement/ ? 1 : 0;

        push @cols, {
            COLUMN_NAME          => $name,
            DATA_TYPE            => $type,
            COLUMN_SIZE          => $size,
            DECIMAL_DIGITS       => $digits,
            COLUMN_DEF           => $default,
            NULLABLE             => $nullable,
            sqlite_autoincrement => $autoinc,
        };
    }

    return @cols;
}


1;

__END__

