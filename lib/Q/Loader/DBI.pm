package Q::Loader::DBI;

use strict;
use warnings;

use base 'Q::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( dbh ) );

use Q::Validate qw( validate DBI_TYPE );

use Q::Column;
use Q::FK;
use Q::Schema;
use Q::Table;

use Scalar::Util qw( looks_like_number );


{
    my $spec = { dbh  => DBI_TYPE };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        return bless \%p, $class;
    }
}

sub make_schema
{
    my $self = shift;

    my $schema = Q::Schema->new( name => $self->_schema_name() );

    $self->_add_tables($schema);
    $self->_add_foreign_keys($schema);

    $schema->set_dbh( $self->dbh() );

    return $schema;
}

sub _schema_name
{
    return $_[0]->dbh()->{Name};
}

sub _add_tables
{
    my $self   = shift;
    my $schema = shift;

    my $sth = $self->dbh()->table_info( undef, undef, '%', 'TABLE,VIEW' );

    while ( my $table_info = $sth->fetchrow_hashref() )
    {
        my $table =
            Q::Table->new
                ( name    => $table_info->{TABLE_NAME},
                  is_view => ( $table_info->{TABLE_TYPE} eq 'VIEW' ? 1 : 0 ),
                );

        $self->_add_columns($table);
        $self->_set_primary_key($table);

        $schema->add_table($table);
    }
}

sub _add_columns
{
    my $self  = shift;
    my $table = shift;

    my $sth = $self->dbh()->column_info( undef, undef, $table->name(), undef );

    while ( my $col_info = $sth->fetchrow_hashref() )
    {
        my %col = ( name         => $col_info->{COLUMN_NAME},
                    type         => $col_info->{DATA_TYPE},
                    generic_type => $col_info->{SQL_DATA_TYPE},
                    # NULLABLE could be 2, which indicate unknown
                    is_nullable  => ( $col_info->{NULLABLE} == 1 ? 1 : 0 ),
                  );
        $col{length} = $col_info->{COLUMN_SIZE}
            if defined $col_info->{COLUMN_SIZE};

        $col{precision} = $col_info->{DECIMAL_DIGITS}
            if defined $col_info->{DECIMAL_DIGITS};

        if ( defined $col_info->{COLUMN_DEF} )
        {
            $col{default} = $self->_default( $col_info->{COLUMN_DEF} );
        }

        $col{is_auto_increment} = $self->_is_auto_increment( $table, $col_info );

        my $col = Q::Column->new(%col);

        $table->add_column($col);
    }
}

sub _default
{
    my $self    = shift;
    my $default = shift;

    if ( $default =~ /^NULL$/i )
    {
        return undef;
    }
    elsif ( $default =~ /^(["'])(.*)\1$/ )
    {
        return $2;
    }
    elsif ( looks_like_number($default) )
    {
        return $default;
    }
    else
    {
        return Q::Literal->term($default);
    }
}

sub _is_auto_increment
{
    return 0;
}

sub _set_primary_key
{
    my $self  = shift;
    my $table = shift;

    my $sth = $self->dbh()->primary_key_info( undef, undef, $table->name() );

    my @pk;
    while ( my $pk_info = $sth->fetchrow_hashref() )
    {
        @pk[ $pk_info->{KEY_SEQ} - 1 ] = $pk_info->{COLUMN_NAME};
    }

    $table->set_primary_key(@pk);
}

sub _add_foreign_keys
{
    my $self   = shift;
    my $schema = shift;

    for my $table ( $schema->tables() )
    {
        my $sth = $self->dbh()->foreign_key_info( undef, undef, $table->name() );

        my %fk;
        while ( my $fk_info = $sth->fetchrow_hashref() )
        {
            my $key =
                ( join "\0",
                  @{$fk_info}{ qw( PKTABLE_NAME PKCOLUMN_NAME FKTABLE_NAME FKCOLUMN_NAME ) }
                );

            $fk{$key}{source}[ $fk_info->{KEY_SEQ} - 1 ] =
                $schema->table( $fk_info->{PKTABLE_NAME} )
                        ->column( $fk_info->{PKCOLUMN_NAME} );

            $fk{$key}{target}[ $fk_info->{KEY_SEQ} - 1 ] =
                $schema->table( $fk_info->{FKTABLE_NAME} )
                       ->column( $fk_info->{FKCOLUMN_NAME} );
        }

        for my $fk_cols ( values %fk )
        {
            my $fk = Q::FK->new( %{$fk_cols} );

            $schema->add_foreign_key($fk);
        }
    }
}


1;
