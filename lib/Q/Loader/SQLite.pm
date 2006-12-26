package Q::Loader::SQLite;

use strict;
use warnings;

use base 'Q::Loader::DBI';

use DBD::SQLite;

use Q::Validate qw( validate SCALAR_TYPE );


unless ( defined &DBD::SQLite::db::column_info )
{
    *DBD::SQLite::db::column_info = \&_sqlite_column_info;
}

sub _sqlite_column_info {
    my($dbh, $catalog, $schema, $table, $column) = @_;

    $column = undef
        if defined $column && $column eq '%';

    my $sth_columns = $dbh->prepare( qq{PRAGMA table_info('$table')} );
    $sth_columns->execute;

    my @names = qw( TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME
                    DATA_TYPE TYPE_NAME COLUMN_SIZE BUFFER_LENGTH
                    DECIMAL_DIGITS NUM_PREC_RADIX NULLABLE
                    REMARKS COLUMN_DEF SQL_DATA_TYPE SQL_DATETIME_SUB
                    CHAR_OCTET_LENGTH ORDINAL_POSITION IS_NULLABLE
                    sqlite_autoincrement
                  );

    my @cols;
    while ( my $col_info = $sth_columns->fetchrow_hashref ) {
        next if defined $column && $column ne $col_info->{name};

        my %col;

        $col{TABLE_NAME} = $table;
        $col{COLUMN_NAME} = $col_info->{name};

        my $type = $col_info->{type};
        if ( $type =~ s/(\w+)\((\d+)(?:,(\d+))?\)/$1/ ) {
            $col{COLUMN_SIZE}    = $2;
            $col{DECIMAL_DIGITS} = $3;
        }

        $col{TYPE_NAME} = $type;

        $col{COLUMN_DEF} = $col_info->{dflt_value}
            if defined $col_info->{dflt_value};

        if ( $col_info->{notnull} ) {
            $col{NULLABLE}    = 0;
            $col{IS_NULLABLE} = 'NO';
        }
        else {
            $col{NULLABLE}    = 1;
            $col{IS_NULLABLE} = 'YES';
        }

        for my $key (@names) {
            $col{$key} = undef
                unless exists $col{$key};
        }

        push @cols, \%col;
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

sub _add_table
{
    my $self       = shift;
    my $schema     = shift;
    my $table_info = shift;

    return if $table_info->{TABLE_NAME} =~ /^sqlite_/;

    $self->SUPER::_add_table( $schema, $table_info );
}

sub _is_auto_increment
{
    my $self     = shift;
    my $table    = shift;
    my $col_info = shift;

    my $name = $col_info->{COLUMN_NAME};

    my @pk = $self->_primary_key( $table->name() );

    # With SQLite3, a table can only have one autoincrement column,
    # and it must be that table's primary key ...
    return 0 unless @pk == 1 && $pk[0] eq $name;

    my $sql = $self->_table_sql( $table->name() );

    # ... therefore if the table's SQL includes the string
    # autoincrement, then the primary key must be auto-incremented.
    return $sql =~ /autoincrement/m ? 1 : 0;
}

sub _primary_key {
    my $self = shift;
    my $name = shift;

    return @{ $self->{__primary_key__}{$name} }
        if $self->{__primary_key__}{$name};

    my @pk = $self->dbh()->primary_key( undef, undef, $name );
    $self->{__primary_key__}{$name} = \@pk;

    return @pk;
}

sub _table_sql {
    my $self = shift;
    my $name = shift;

    return $self->{__table_sql__}{$name}
        if $self->{__table_sql__}{$name};

    return $self->{__table_sql__}{$name} =
        $self->dbh()->selectcol_arrayref
            ( 'SELECT sql FROM sqlite_master WHERE tbl_name = ?', {}, $name )->[0];
}

sub _default
{
    my $self    = shift;
    my $default = shift;

    if ( $default =~ /^NULL$/i )
    {
        return Q::Literal->null();
    }
    elsif ( $default =~ /CURRENT_(?:TIME(?:STAMP)?|DATE)/ )
    {
        return Q::Literal->term($default);
    }
    else
    {
        return $default;
    }
}


1;

__END__

