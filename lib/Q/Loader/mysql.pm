package Q::Loader::mysql;

use strict;
use warnings;

use base 'Q::Loader::DBI';

use DBD::mysql;

use Q::Literal;


package DBD::mysql::Fixup;

BEGIN
{
    unless ( defined &DBD::mysql::db::primary_key_info )
    {
        *DBD::mysql::db::primary_key_info = \&_primary_key_info;
    }

    if ( DBD::mysql->VERSION <= 4 )
    {
        no warnings 'redefine';
        no warnings 'prototype';
        *DBD::mysql::db::table_info = \&_new_table_info;
        *DBD::mysql::db::_has_views = \&_has_views;
        *DBD::mysql::db::column_info = \&_new_column_info;

        DBI->import(':sql_types');

        require DBI::Const::GetInfoType;
        DBI::Const::GetInfoType->import();
    }
}

{
    my $names = ['TABLE_CAT', 'TABLE_SCHEM', 'TABLE_NAME',
		 'TABLE_TYPE', 'REMARKS'];

    sub _new_table_info ($) {
	my $dbh = shift;

        my $sql = _has_views($dbh) ? 'SHOW FULL TABLES' : 'SHOW TABLES';
	my $sth = $dbh->prepare($sql);
	return undef unless $sth;
	if (!$sth->execute()) {
	  return DBI::set_err($dbh, $sth->err(), $sth->errstr());
        }
	my @tables;
	while (my $ref = $sth->fetchrow_arrayref()) {
          my $type = $ref->[1] && $ref->[1] =~ /view/i ? 'VIEW' : 'TABLE';
	  push(@tables, [ undef, undef, $ref->[0], $type, undef ]);
        }
	my $dbh2;
	if (!($dbh2 = $dbh->{'~dbd_driver~_sponge_dbh'})) {
	    $dbh2 = $dbh->{'~dbd_driver~_sponge_dbh'} =
		DBI->connect("DBI:Sponge:");
	    if (!$dbh2) {
	        DBI::set_err($dbh, 1, $DBI::errstr);
		return undef;
	    }
	}
	my $sth2 = $dbh2->prepare("SHOW TABLES", { 'rows' => \@tables,
						   'NAME' => $names,
						   'NUM_OF_FIELDS' => 5 });
	if (!$sth2) {
	    DBI::set_err($sth2, $dbh2->err(), $dbh2->errstr());
	}
	$sth2;
    }

    sub _has_views {
        my $dbh = shift;

        my ($maj, $min, $point) =
            $dbh->get_info($GetInfoType{SQL_DBMS_VER}) =~ /(\d+)\.(\d+)\.(\d+)/;

        return 1 if $maj >= 5 && $point >= 1;
    }
}

sub _new_column_info {
    my ($dbh, $catalog, $schema, $table, $column) = @_;
    return $dbh->set_err(1, "column_info doesn't support table wildcard")
	if $table !~ /^\w+$/;
    return $dbh->set_err(1, "column_info doesn't support column selection")
	if $column ne "%";

    my $table_id = $dbh->quote_identifier($catalog, $schema, $table);

    my @names = qw(
	TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME
	DATA_TYPE TYPE_NAME COLUMN_SIZE BUFFER_LENGTH DECIMAL_DIGITS
	NUM_PREC_RADIX NULLABLE REMARKS COLUMN_DEF
	SQL_DATA_TYPE SQL_DATETIME_SUB CHAR_OCTET_LENGTH
	ORDINAL_POSITION IS_NULLABLE CHAR_SET_CAT
	CHAR_SET_SCHEM CHAR_SET_NAME COLLATION_CAT COLLATION_SCHEM COLLATION_NAME
	UDT_CAT UDT_SCHEM UDT_NAME DOMAIN_CAT DOMAIN_SCHEM DOMAIN_NAME
	SCOPE_CAT SCOPE_SCHEM SCOPE_NAME MAX_CARDINALITY
	DTD_IDENTIFIER IS_SELF_REF
	mysql_is_pri_key mysql_type_name mysql_is_auto_increment mysql_values
    );
    my %col_info;

    local $dbh->{FetchHashKeyName} = 'NAME_lc';
    my $desc_sth = $dbh->prepare("DESCRIBE $table_id");
    my $desc = $dbh->selectall_arrayref($desc_sth, { Columns=>{} });
    my $ordinal_pos = 0;
    foreach my $row (@$desc) {
	my $type = $row->{type};
	$type =~ m/^(\w+)(?:\((.*?)\))?\s*(.*)/;
	my $basetype = lc($1);
        my $typemod = $2;
        my $attr = $3;

	my $info = $col_info{ $row->{field} } = {
	    TABLE_CAT   => $catalog,
	    TABLE_SCHEM => $schema,
	    TABLE_NAME  => $table,
	    COLUMN_NAME => $row->{field},
	    NULLABLE    => ($row->{null} eq 'YES') ? 1 : 0,
	    IS_NULLABLE => ($row->{null} eq 'YES') ? "YES" : "NO",
	    TYPE_NAME   => uc($basetype),
	    COLUMN_DEF  => $row->{default},
	    ORDINAL_POSITION => ++$ordinal_pos,
	    mysql_is_pri_key => ($row->{key}  eq 'PRI'),
	    mysql_type_name  => $row->{type},
            mysql_is_auto_increment => ($row->{extra} =~ /auto_increment/i ? 1 : 0),
	};
	# This code won't deal with a pathalogical case where a value
	# contains a single quote followed by a comma, and doesn't unescape
	# any escaped values. But who would use those in an enum or set?
	my @type_params = ($typemod && index($typemod,"'")>=0)
			? ("$typemod," =~ /'(.*?)',/g)  # assume all are quoted
			: split /,/, $typemod||'';      # no quotes, plain list
	s/''/'/g for @type_params;                      # undo doubling of quotes
	my @type_attr = split / /, $attr||'';
	#warn "$type: $basetype [@type_params] [@type_attr]\n";

	$info->{DATA_TYPE} = SQL_VARCHAR();
	if ($basetype =~ /^(char|varchar|\w*text|\w*blob)/) {
	    $info->{DATA_TYPE} = SQL_CHAR() if $basetype eq 'char';
	    if ($type_params[0]) {
		$info->{COLUMN_SIZE} = $type_params[0];
	    }
	    else {
		$info->{COLUMN_SIZE} = 65535;
		$info->{COLUMN_SIZE} = 255        if $basetype =~ /^tiny/;
		$info->{COLUMN_SIZE} = 16777215   if $basetype =~ /^medium/;
		$info->{COLUMN_SIZE} = 4294967295 if $basetype =~ /^long/;
	    }
	}
	elsif ($basetype =~ /^(binary|varbinary)/) {
	    $info->{COLUMN_SIZE} = $type_params[0];
	    # SQL_BINARY & SQL_VARBINARY are tempting here but don't match the
	    # semantics for mysql (not hex). SQL_CHAR &  SQL_VARCHAR are correct here.
	    $info->{DATA_TYPE} = ($basetype eq 'binary') ? SQL_CHAR() : SQL_VARCHAR();
	}
	elsif ($basetype =~ /^(enum|set)/) {
	    if ($basetype eq 'set') {
		$info->{COLUMN_SIZE} = length(join ",", @type_params);
	    }
	    else {
		my $max_len = 0;
		length($_) > $max_len and $max_len = length($_) for @type_params;
		$info->{COLUMN_SIZE} = $max_len;
	    }
	    $info->{"mysql_values"} = \@type_params;
	}
	elsif ($basetype =~ /int/) { # big/medium/small/tiny etc + unsigned?
	    $info->{DATA_TYPE} = SQL_INTEGER();
	    $info->{NUM_PREC_RADIX} = 10;
	    $info->{COLUMN_SIZE} = $type_params[0];
	}
	elsif ($basetype =~ /^decimal/) {
	    $info->{DATA_TYPE} = SQL_DECIMAL();
	    $info->{NUM_PREC_RADIX} = 10;
	    $info->{COLUMN_SIZE}    = $type_params[0];
	    $info->{DECIMAL_DIGITS} = $type_params[1];
	}
	elsif ($basetype =~ /^(float|double)/) {
	    $info->{DATA_TYPE} = ($basetype eq 'float') ? SQL_FLOAT() : SQL_DOUBLE();
	    $info->{NUM_PREC_RADIX} = 2;
	    $info->{COLUMN_SIZE} = ($basetype eq 'float') ? 32 : 64;
	}
	elsif ($basetype =~ /date|time/) { # date/datetime/time/timestamp
	    if ($basetype eq 'time' or $basetype eq 'date') {
		#$info->{DATA_TYPE}   = ($basetype eq 'time') ? SQL_TYPE_TIME() : SQL_TYPE_DATE();
                $info->{DATA_TYPE}   = ($basetype eq 'time') ? SQL_TIME() : SQL_DATE(); 
		$info->{COLUMN_SIZE} = ($basetype eq 'time') ? 8 : 10;
	    }
	    else { # datetime/timestamp
		#$info->{DATA_TYPE}     = SQL_TYPE_TIMESTAMP();
		$info->{DATA_TYPE}     = SQL_TIMESTAMP();
		$info->{SQL_DATA_TYPE} = SQL_DATETIME();
	        $info->{SQL_DATETIME_SUB} = $info->{DATA_TYPE} - ($info->{SQL_DATA_TYPE} * 10);
		$info->{COLUMN_SIZE}   = ($basetype eq 'datetime') ? 19 : $type_params[0] || 14;
	    }
	    $info->{DECIMAL_DIGITS} = 0; # no fractional seconds
	}
	elsif ($basetype eq 'year') {	# no close standard so treat as int
	    $info->{DATA_TYPE} = SQL_INTEGER();
	    $info->{NUM_PREC_RADIX} = 10;
	    $info->{COLUMN_SIZE} = 4;
	}
	else {
	    Carp::carp("column_info: unrecognized column type '$basetype' of $table_id.$row->{field} treated as varchar");
	}
	$info->{SQL_DATA_TYPE} ||= $info->{DATA_TYPE};
	#warn Dumper($info);
    }

    my $sponge = DBI->connect("DBI:Sponge:", '','')
	or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");
    my $sth = $sponge->prepare("column_info $table", {
	rows => [ map { [ @{$_}{@names} ] } values %col_info ],
	NUM_OF_FIELDS => scalar @names,
	NAME => \@names,
    }) or return $dbh->DBI::set_err($sponge->err(), $sponge->errstr());

    return $sth;
}

sub _primary_key_info {
    my ($dbh, $catalog, $schema, $table) = @_;
    return $dbh->set_err(1, "primary_key doesn't support table wildcard")
	if $table !~ /^\w+$/;

    my $table_id = $dbh->quote_identifier($catalog, $schema, $table);

    local $dbh->{FetchHashKeyName} = 'NAME_lc';
    my $index_sth = $dbh->prepare("SHOW INDEX FROM $table_id");
    my $index = $dbh->selectall_arrayref($index_sth, { Columns=>{} });

    my @names = qw(
        TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME
        KEY_SEQ PK_NAME
    );

    my @pk_info;
    for my $row (grep {$_->{key_name} eq 'PRIMARY'} @$index) {
        push @pk_info, {
            TABLE_CAT   => $catalog,
            TABLE_SCHEM => $schema,
            TABLE_NAME  => $table,
            COLUMN_NAME => $row->{column_name},
            KEY_SEQ     => $row->{seq_in_index},
            PK_NAME     => $row->{key_name},
        };
    }

    my $sponge = DBI->connect("DBI:Sponge:", '','')
	or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");
    my $sth = $sponge->prepare("column_info $table", {
	rows => [ map { [ @{$_}{@names} ] } @pk_info ],
	NUM_OF_FIELDS => scalar @names,
	NAME => \@names,
    }) or return $dbh->DBI::set_err($sponge->err(), $sponge->errstr());

    return $sth;
}

package Q::Loader::mysql;

sub _column_params
{
    my $self     = shift;
    my $table    = shift;
    my $col_info = shift;

    my %col = $self->SUPER::_column_params( $table, $col_info );

    # DBD::mysql adds the max length for some data types to the column
    # info, but we only care about user-specified lengths.
    #
    # Unfortunately, MySQL itself adds a length to some types (notable
    # integer types) that isn't really useful, but it's impossible
    # (AFAIK) to distinguish between a length specified by the user
    # and one specified by the DBMS.
    delete $col{length}
        if (    $col{type} =~ /(?:text|blob)$/i
             || $col{type} =~ /^(?:float|double)/i
             || $col{type} =~ /^(?:enum|set)/i
             || (    $col{type} =~ /^(?:date|time)/i
                  && lc $col{type} ne 'timestamp' )
           );

    delete $col{precision}
        if $col{type} =~ /date|time/o;

    delete $col{default}
        if (    exists $col{default}
             && $col_info->{COLUMN_DEF} eq ''
             && $col_info->{TYPE_NAME} =~ /int|float|double/i
           );

    return %col;
}

sub _is_auto_increment
{
    my $self     = shift;
    my $table    = shift;
    my $col_info = shift;

    return $col_info->{mysql_is_auto_increment} ? 1 : 0;
}

sub _table_info
{
    my $self = shift;
    my $name = shift;

    return $self->{__table_info__}{$name}
        if $self->{__table_info__}{$name};

    return $self->{__table_info__}{$name} =
        $self->dbh()->selectall_arrayref
            ( "DESCRIBE " . $self->dbh()->quote_identifier($name) );
}

sub _default
{
    my $self     = shift;
    my $default  = shift;
    my $col_info = shift;

    if ( $default =~ /^NULL$/i )
    {
        return Q::Literal->null();
    }
    elsif ( $default =~ /^CURRENT_TIMESTAMP$/i )
    {
        return Q::Literal->term($default);
    }
    else
    {
        return $default;
    }
}


1;
