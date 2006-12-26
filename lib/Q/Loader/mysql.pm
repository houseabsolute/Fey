package Q::Loader::mysql;

use strict;
use warnings;

use base 'Q::Loader::DBI';

use DBD::mysql;

use Q::Literal;


unless ( defined &DBD::mysql::db::primary_key )
{
    *DBD::mysql::db::primary_key = \&_primary_key;
}

sub _primary_key {
    my ($dbh, $catalog, $schema, $table) = @_;
    return $dbh->set_err(1, "primary_key doesn't support table wildcard")
	if $table !~ /^\w+$/;

    my $table_id = $dbh->quote_identifier($catalog, $schema, $table);

    local $dbh->{FetchHashKeyName} = 'NAME_lc';
    my $index_sth = $dbh->prepare("SHOW INDEX FROM $table_id");
    my $index = $dbh->selectall_arrayref($index_sth, { Columns=>{} });

    my @pk;
    foreach my $row (grep { $_->{key_name} eq 'PRIMARY' } @$index) {
        $pk[ $row->{seq_in_index} - 1 ] = $row->{column_name};
    }

    return @pk;
}

# Not sure why DBD::mysql is not getting this right.
sub _is_view
{
    my $self       = shift;
    my $table_info = shift;

    my $sth =
        $self->dbh()->prepare
            ( 'SHOW CREATE TABLE '
              . $self->dbh()->quote_identifier( $table_info->{TABLE_NAME} )
            );
    $sth->execute();

    return $sth->{NAME}[1] =~ /view/i ? 1 : 0;
}

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

    my $table_info = $self->_table_info( $table->name() );

    my ($row) =
        grep { $_->[0] eq $col_info->{COLUMN_NAME} } @{$table_info};

    return $row && $row->[5] =~ /AUTO_INCREMENT/i ? 1 : 0;
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
