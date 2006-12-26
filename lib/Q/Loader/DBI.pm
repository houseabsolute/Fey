package Q::Loader::DBI;

use strict;
use warnings;

use base 'Q::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( dbh quoter ) );

use Q::Validate qw( validate SCALAR_TYPE DBI_TYPE );

use Q::Column;
use Q::FK;
use Q::Schema;
use Q::Table;
use Q::Quoter;

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

{
    my $spec = { name => SCALAR_TYPE( optional => 1 ) };
    sub make_schema
    {
        my $self = shift;
        my %p    = validate( @_, $spec );

        my $name = delete $p{name} || $self->dbh()->{Name};

        my $schema = Q::Schema->new( name => $name );

        $self->{quoter} = Q::Quoter->new( dbh => $self->dbh() );

        $self->_add_tables($schema);
        $self->_add_foreign_keys($schema);

        $schema->set_dbh( $self->dbh() );

        return $schema;
    }
}

sub _add_tables
{
    my $self   = shift;
    my $schema = shift;

    my $sth =
        $self->dbh()->table_info
            ( $self->_catalog_name(), $self->_schema_name(),
              '%', 'TABLE,VIEW' );

    while ( my $table_info = $sth->fetchrow_hashref() )
    {
        $self->_add_table( $schema, $table_info );
    }
}

sub _catalog_name { undef }

sub _schema_name { undef }

sub _add_table
{
    my $self       = shift;
    my $schema     = shift;
    my $table_info = shift;

    my $name = $self->quoter()->unquote_identifier( $table_info->{TABLE_NAME} );

    my $table =
        Q::Table->new
            ( name    => $name,
              is_view => $self->_is_view($table_info),
            );

    $self->_add_columns($table);
    $self->_set_primary_key($table);

    $schema->add_table($table);
}

sub _is_view { $_[1]->{TABLE_TYPE} eq 'VIEW' ? 1 : 0 }

sub _add_columns
{
    my $self  = shift;
    my $table = shift;

    my $sth = $self->dbh()->column_info( undef, undef, $table->name(), '%' );

    while ( my $col_info = $sth->fetchrow_hashref() )
    {
        my %col = $self->_column_params( $table, $col_info );

        my $col = Q::Column->new(%col);

        $table->add_column($col);
    }
}

sub _column_params
{
    my $self     = shift;
    my $table    = shift;
    my $col_info = shift;

    my $name = $self->quoter()->unquote_identifier( $col_info->{COLUMN_NAME} );

    my %col = ( name         => $name,
                type         => $col_info->{TYPE_NAME},
                # NULLABLE could be 2, which indicate unknown
                is_nullable  => ( $col_info->{NULLABLE} == 1 ? 1 : 0 ),
              );

    $col{length} = $col_info->{COLUMN_SIZE}
        if defined $col_info->{COLUMN_SIZE};

    $col{precision} = $col_info->{DECIMAL_DIGITS}
        if defined $col_info->{DECIMAL_DIGITS};

    if ( defined $col_info->{COLUMN_DEF} )
    {
        my $default = $self->_default( $col_info->{COLUMN_DEF}, $col_info );
        $col{default} = $default
            if defined $default;
    }

    $col{is_auto_increment} = $self->_is_auto_increment( $table, $col_info );

    return %col;
}

sub _default
{
    my $self    = shift;
    my $default = shift;

    if ( $default =~ /^NULL$/i )
    {
        return Q::Literal->null();
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

    my @pk =
        ( map { $self->quoter()->unquote_identifier($_) }
          $self->dbh()->primary_key( undef, undef, $table->name() )
        );

    $table->set_primary_key(@pk);
}

sub _add_foreign_keys
{
    my $self   = shift;
    my $schema = shift;

    my @keys = qw( UK_TABLE_NAME UK_COLUMN_NAME FK_TABLE_NAME FK_COLUMN_NAME );

    for my $table ( $schema->tables() )
    {
        my $sth =
            $self->dbh()->foreign_key_info
                ( undef, undef, $table->name(),
                  undef, undef, undef,
                );

        next unless $sth;

        my %fk;
        while ( my $fk_info = $sth->fetchrow_hashref() )
        {
            for my $k (@keys)
            {
                $fk_info->{$k} = $self->quoter()->unquote_identifier( $fk_info->{$k} );
            }

            my $key = $fk_info->{FK_NAME};

            $fk{$key}{source}[ $fk_info->{ORDINAL_POSITION} - 1 ] =
                $schema->table( $fk_info->{UK_TABLE_NAME} )
                        ->column( $fk_info->{UK_COLUMN_NAME} );

            $fk{$key}{target}[ $fk_info->{ORDINAL_POSITION} - 1 ] =
                $schema->table( $fk_info->{FK_TABLE_NAME} )
                       ->column( $fk_info->{FK_COLUMN_NAME} );
        }

        for my $fk_cols ( values %fk )
        {
            # This is a gross workaround for what seems to be a bug in
            # DBD::Pg. The ORDINAL_POSITION is sequential across
            # different fks, so we end up with undef in the array.
            for my $k ( qw( source target ) )
            {
                $fk_cols->{$k} = [ grep { defined } @{ $fk_cols->{$k} } ]
            }

            my $fk = Q::FK->new( %{$fk_cols} );

            $schema->add_foreign_key($fk);
        }
    }
}


1;
