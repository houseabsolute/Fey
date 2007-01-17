package Fey::Column;

use strict;
use warnings;

use base 'Fey::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( name type generic_type length precision
          is_auto_increment is_nullable default
          table ) );

use Class::Trait ( 'Fey::Trait::ColumnLike' );


use Scalar::Util qw( blessed weaken );

use Fey::Exceptions qw( object_state_error );
use Fey::Validate
    qw( validate validate_pos
        SCALAR UNDEF OBJECT
        SCALAR_TYPE BOOLEAN_TYPE
        POS_INTEGER_TYPE POS_OR_ZERO_INTEGER_TYPE
        TABLE_TYPE );

use Fey::Column::Alias;
use Fey::Literal;


{
    my $gen_type_re =
        qr/text|blob|integer|float|date|datetime|time|boolean|other/;

    my $spec =
        { name              => SCALAR_TYPE,
          generic_type      => SCALAR_TYPE( regex    => $gen_type_re,
                                            optional => 1,
                                          ),
          type              => SCALAR_TYPE,
          length            => POS_INTEGER_TYPE( optional => 1 ),
          precision         => POS_OR_ZERO_INTEGER_TYPE( optional => 1,
                                                         depends => [ 'length' ] ),
          is_auto_increment => BOOLEAN_TYPE( default => 0 ),
          is_nullable       => BOOLEAN_TYPE( default => 0 ),
          default           =>
          { type      => SCALAR|UNDEF|OBJECT,
            optional  => 1,
            callbacks =>
            { 'is a scalar, undef, or literal' =>
              sub {    ! blessed $_[0]
                    || $_[0]->isa('Fey::Literal') },
            },
          },
        };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        $p{generic_type} = $class->_guess_generic_type( $p{type} )
            unless defined $p{generic_type};

        $p{default} = Fey::Literal->new_from_scalar( $p{default} )
            if exists $p{default} && ! blessed $p{default};

        my $self = bless \%p, $class;

        return $self;
    }
}

{
    my @TypesRe =
        ( [ text     => qr/(?:text|char(?:acter)?)\b/i ],
          [ blob     => qr/blob\b|bytea\b/i ],
          # The year type comes from MySQL
          [ integer  => qr/(?:int(?:eger)?\d*|year)\b/i ],
          [ float    => qr/(?:float\d*|decimal|real|double|money|numeric)\b/i ],
          # MySQL's timestamp is not always a datetime, it depends on
          # the length of the column, but this is the best _guess_.
          [ datetime => qr/datetime\b|^timestamp/i ],
          [ date     => qr/date\b/i ],
          [ time     => qr/^time|time\b/i ],
          [ boolean  => qr/\bbool/i ],
        );

    sub _guess_generic_type
    {
        my $type = $_[1];

        for my $p (@TypesRe)
        {
            return $p->[0] if $type =~ /$p->[1]/;
        }

        return 'other';
    }
}

{
    # This method is private but intended to be called by Fey::Table and
    # Fey::Table::Alias but not by anything else.
    my $spec = ( { type => UNDEF | OBJECT,
                   callbacks =>
                   { 'undef or table' =>
                     sub { ! defined $_[0]
                           || $_[0]->isa('Fey::Table')
                           || $_[0]->isa('Fey::Table::Alias') },
                   },
                 } );
    sub _set_table
    {
        my $self    = shift;
        my ($table) = validate_pos( @_, $spec );

        $self->{table} = $table;
        weaken $self->{table}
            if $self->{table};

        return $self
    }
}

sub _clone
{
    my $self = shift;

    my %clone = %$self;

    return bless \%clone, ref $self;
}

sub is_alias { 0 }

sub alias
{
    my $self = shift;

    return Fey::Column::Alias->new( column => $self, @_ );
}

sub sql
{
    $_[1]->join_table_and_column
        ( $_[1]->quote_identifier( $_[0]->_containing_table_name_or_alias() ),
          $_[1]->quote_identifier( $_[0]->name() )
        );
}

sub sql_with_alias { goto &sql }

sub sql_or_alias { goto &sql }

sub id
{
    my $self = shift;

    my $table = $self->table();

    object_state_error
        'The id() method cannot be called on a column object which has no table.'
            unless $table;

    return $table->id() . '.' . $self->name();
}


1;

__END__

=head1 NAME

Fey::Column - Represents a column

=head1 SYNOPSIS

  my $column = Fey::Column->new( name              => 'user_id',
                                 type              => 'integer',
                                 is_auto_increment => 1,
                               );

=head1 DESCRIPTION

This class represents a column in a table.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Column->new()

This method constructs a new C<Fey::Column> object. It takes the
following parameters:

=over 4

=item * name - required

The name of the column.

=item * type - required

The type of the column. This should be a string. Do not include
modifiers like length or precision.

=item * generic_type - optional

This should be one of the following types:

=over 8

=item * text

=item * blob

=item * integer

=item * float

=item * date

=item * datetime

=item * time

=item * boolean

=item * other

=back

This indicate a generic type for the column, which is intended to
allow for a common description of column types across different DBMS
platforms.

If this parameter is not specified, then the constructor code will
attempt to determine a reasonable value, defaulting to "other" if
necessary.

=item * length - optional

The length of the column. This must be a positive integer.

=item * precision - optional

The precision of the column, for float-type columns. This must be an
integer >= 0.

=item * is_auto_increment - defaults to 0

This indicates whether or not the column is auto-incremented.

=item * is_nullable - defaults to 0

A boolean indicating whether the column is nullab.e

=item * default - optional

This must be either a scalar (including undef) or a C<Fey::Literal>
object. If a scalar is provided, it is turned into a C<Fey::Literal>
object via C<< Fey::Literal->new_from_scalar() >>.

=back

=head2 $column->name()

=head2 $column->type()

=head2 $column->generic_type()

=head2 $column->length()

=head2 $column->precision()

=head2 $column->is_auto_increment()

=head2 $column->is_nullable()

=head2 $column->default()

Returns the specified attribute.

=head2 $column->table()

Returns the C<Fey::Table> object to which the column belongs, if any.

=head2 $column->alias(%p)

This method returns a new C<Fey::Column::Alias> object based on the
column. Any parameters passed to this method will be passed through to
C<< Fey::Column::Alias->new() >>.

=head2 $column->is_alias()

Always returns false.

=head2 $column->sql()

=head2 $column->sql_with_alias()

=head2 $column->sql_or_alias()

Returns the appropriate SQL snippet for the column.

=head2 $column->id()

Returns a unique identifier for the column.

=head1 TRAITS

This class does the C<Fey::Trait::ColumnLike> trait.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
