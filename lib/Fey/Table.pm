package Fey::Table;

use strict;
use warnings;

use base 'Fey::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( name is_view schema ) );

use Scalar::Util qw( blessed weaken );

use Fey::Exceptions qw( param_error );
use Fey::Validate
    qw( validate validate_pos
        UNDEF OBJECT
        SCALAR_TYPE BOOLEAN_TYPE
        COLUMN_TYPE COLUMN_OR_NAME_TYPE
        SCHEMA_TYPE );

use Fey::Column;
use Fey::Table::Alias;
use Scalar::Util qw( blessed );


{
    my $spec = { name    => SCALAR_TYPE,
                 is_view => BOOLEAN_TYPE( default => 0 ),
               };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $self =
            bless { %p,
                    columns => {},
                  }, $class;

        return $self;
    }
}

{
    my @spec = (COLUMN_TYPE);
    sub add_column
    {
        my $self = shift;
        my ($col) = validate_pos( @_, @spec );

        my $name = $col->name();
        param_error "The table already has a column named $name."
            if $self->column($name);

        $self->{columns}{$name} = $col;

        $col->_set_table($self);

        return $self;
    }
}

{
    my $spec = (SCALAR_TYPE);
    sub column
    {
        my $self = shift;
        my ($name) = validate_pos( @_, $spec );

        return unless $self->{columns}{$name};
        return $self->{columns}{$name};
    }
}

sub columns
{
    my $self = shift;

    return values %{ $self->{columns} } unless @_;

    return map { $self->{columns}{$_} || () } @_;
}

{
    my $spec = (COLUMN_OR_NAME_TYPE);
    sub remove_column
    {
        my $self = shift;
        my ($col) = validate_pos( @_, $spec );

        $col = $self->column($col)
            unless blessed $col;

        if ( my $schema = $self->schema() )
        {
            for my $fk ( grep { $_->has_column($col) }
                         $schema->foreign_keys_for_table($self) )
            {
                $schema->remove_foreign_key($fk);
            }
        }

        my $name = $col->name();

        $self->set_primary_key
            ( grep { $_->name() ne $name } $self->primary_key() );

        delete $self->{columns}{$name};
        $col->_set_table(undef);

        return $self;
    }
}

{
    my $spec = (COLUMN_OR_NAME_TYPE);
    sub set_primary_key
    {
        my $self = shift;
        my @names =
            ( map { ref $_ ? $_->name() : $_ }
              validate_pos( @_, ($spec) x @_ )
            );

        for my $name (@names)
        {
            param_error "The column $name is not part of the " . $self->name() . ' table.'
                unless $self->column($name);
        }

        $self->{pk} = [ map { $self->column($_) } @names ];

        return $self;
    }
}

sub primary_key { @{ $_[0]->{pk} || [] } }

{
    # This method is private but intended to be called by Fey::Schema,
    # but not by anything else.
    my $spec = ( { type => UNDEF | OBJECT,
                   callbacks =>
                   { 'undef or schema' =>
                     sub { ! defined $_[0]
                           || $_[0]->isa('Fey::Schema') },
                   },
                 } );
    sub _set_schema
    {
        my $self     = shift;
        my ($schema) = validate_pos( @_, $spec );

        $self->{schema} = $schema;
        weaken $self->{schema}
            if $self->{schema};

        return $self
    }
}

sub alias
{
    my $self = shift;

    return Fey::Table::Alias->new( table => $self, @_ );
}

sub is_alias { 0 }

sub sql
{
    return $_[1]->quote_identifier( $_[0]->name() );
}

sub sql_with_alias { goto &sql }

sub id { $_[0]->name() }


1;

__END__
