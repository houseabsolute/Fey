package Fey::Schema;

use strict;
use warnings;

use base 'Fey::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( name dbh ) );

use Fey::Exceptions qw( param_error );
use Fey::Validate
    qw( validate validate_pos
        SCALAR_TYPE ARRAYREF_TYPE
        TABLE_TYPE TABLE_OR_NAME_TYPE
        FK_TYPE DBI_TYPE );

use Fey::Query;
use Fey::Table;
use Scalar::Util qw( blessed );


{
    my $spec = { name        => SCALAR_TYPE,
                 query_class => SCALAR_TYPE( default => 'Fey::Query' ),
               };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $self =
            bless { %p,
                    tables => {},
                  }, $class;

        $self->_load_query_class();

        return $self;
    }
}

sub _load_query_class
{
    my $self = shift;

    return if $self->{query_class}->can('new');

    eval "use $self->{query_class}";
    die $@ if $@;
}

{
    my $spec = (TABLE_TYPE);
    sub add_table
    {
        my $self  = shift;
        my ($table) = validate_pos( @_, $spec );

        my $name = $table->name();
        param_error "The schema already contains a table named $name."
            if $self->table($name);

        $self->{tables}{$name} = $table;
        $table->_set_schema($self);

        return $self;
    }
}

{
    my $spec = (SCALAR_TYPE);
    sub table
    {
        my $self = shift;
        my ($name) = validate_pos( @_, $spec );

        return unless $self->{tables}{$name};
        return $self->{tables}{$name};
    }
}

sub tables
{
    my $self = shift;

    return values %{ $self->{tables} } unless @_;

    return map { $self->{tables}{$_} || () } @_;
}

{
    my $spec = (TABLE_OR_NAME_TYPE);
    sub remove_table
    {
        my $self = shift;
        my ($table) = validate_pos( @_, $spec );

        $table = $self->table($table)
            unless blessed $table;

        for my $fk ( $self->foreign_keys_for_table($table) )
        {
            $self->remove_foreign_key($fk);
        }

        my $name = $table->name();

        delete $self->{tables}{$name};
        $table->_set_schema(undef);

        return $self;
    }
}

{
    my $spec = (DBI_TYPE);
    sub set_dbh
    {
        my $self  = shift;
        my ($dbh) = validate_pos( @_, $spec );

        $self->{dbh} = $dbh;

        return $self;
    }
}

{
    my $spec = (FK_TYPE);
    sub add_foreign_key
    {
        my $self = shift;
        my ($fk) = validate_pos( @_, $spec );

        my $fk_id = $fk->id();

        my $source_table_name = $fk->source_table()->name();
        for my $col_name ( map { $_->name() } $fk->source_columns() )
        {
            $self->{fk}{$source_table_name}{$col_name}{$fk_id} = $fk;
        }

        my $target_table_name = $fk->target_table()->name();
        for my $col_name ( map { $_->name() } $fk->target_columns() )
        {
            $self->{fk}{$target_table_name}{$col_name}{$fk_id} = $fk;
        }

        return $self;
    }
}

{
    my $spec = (FK_TYPE);
    sub remove_foreign_key
    {
        my $self = shift;
        my ($fk) = validate_pos( @_, $spec );

        my $fk_id = $fk->id();

        my $source_table_name = $fk->source_table()->name();
        for my $col_name ( map { $_->name() } $fk->source_columns() )
        {
            delete $self->{fk}{$source_table_name}{$col_name}{$fk_id};
        }

        my $target_table_name = $fk->target_table()->name();
        for my $col_name ( map { $_->name() } $fk->target_columns() )
        {
            delete $self->{fk}{$target_table_name}{$col_name}{$fk_id};
        }

        return $self;
    }
}

{
    my $spec = (TABLE_OR_NAME_TYPE);
    sub foreign_keys_for_table
    {
        my $self    = shift;
        my ($table) = validate_pos( @_, $spec );

        my $name = blessed $table ? $table->name() : $table;

        return
            ( map { values %{ $self->{fk}{$name}{$_} } }
              keys %{ $self->{fk}{$name} || {} }
            );
    }
}

{
    my $spec = (TABLE_OR_NAME_TYPE);
    sub foreign_keys_between_tables
    {
        my $self    = shift;
        my ( $table1, $table2 ) = validate_pos( @_, $spec, $spec );

        my $name1 = blessed $table1 ? $table1->name() : $table1;
        my $name2 = blessed $table2 ? $table2->name() : $table2;

        return
            ( grep { $_->has_tables( $name1, $name2 ) }
              map { values %{ $self->{fk}{$name1}{$_} } }
              keys %{ $self->{fk}{$name1} || {} }
            );
    }
}

sub query { $_[0]->{query_class}->new( dbh => $_[0]->dbh() ) }


1;

__END__
