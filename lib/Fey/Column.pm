package Fey::Column;

use strict;
use warnings;

use Scalar::Util qw( blessed weaken );

use Fey::Exceptions qw( param_error object_state_error );
use Fey::Validate
    qw( validate validate_pos
        SCALAR UNDEF OBJECT
        SCALAR_TYPE BOOLEAN_TYPE
        POS_INTEGER_TYPE POS_OR_ZERO_INTEGER_TYPE
        TABLE_TYPE );

use Moose::Policy 'MooseX::Policy::SemiAffordanceAccessor';
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints qw( subtype as where coerce from via );

with 'Fey::Role::ColumnLike';

has 'name' =>
    ( is       => 'ro',
      isa      => 'Str',
      required => 1,
    );

subtype 'GenericTypeName'
    => as 'Str'
    => where { /^(?:text|blob|integer|float|date|datetime|time|boolean|other)$/xism };
has 'generic_type' =>
    ( is      => 'ro',
      isa     => 'GenericTypeName',
      lazy    => 1,
      default => \&_guess_generic_type,
    );

has type =>
    ( is       => 'ro',
      isa      => 'Str',
      required => 1,
    );

subtype 'PosInteger'
    => as 'Int'
    => where { $_ > 0 };
has length =>
    ( is       => 'ro',
      isa      => 'PosInteger',
      required => 0
    );

subtype 'PosOrZeroInteger'
    => as 'Int'
    => where { $_ >= 0 };
# How to say that precision requires length as well?
has precision =>
    ( is       => 'ro',
      isa      => 'PosOrZeroInteger',
      required => 0
    );

has is_auto_increment =>
    ( is      => 'ro',
      isa     => 'Bool',
      default => 0,
    );

has is_nullable =>
    ( is      => 'ro',
      isa     => 'Bool',
      default => 0,
    );

subtype 'DefaultValue'
    => as 'Fey::Literal';
coerce 'DefaultValue'
    => from 'Undef'
    => via { Fey::Literal::Null->new() }
    => from 'Value'
    => via { Fey::Literal->new_from_scalar($_) };

has default =>
    ( is     => 'ro',
      isa    => 'DefaultValue',
      coerce => 1,
    );

has 'table' =>
    ( is       => 'rw',
      isa      => 'Undef | Fey::Table | Fey::Table::Alias',
      weak_ref => 1,
      writer   => '_set_table',
    );

use Fey::Column::Alias;
use Fey::Literal;
use Fey::Table;
use Fey::Table::Alias;


sub BUILD
{
    my $self = shift;
    my $p    = shift;

    param_error "Cannot set precision unless length is also set"
        if defined $p->{precision} && ! $p->{length};

    return;
}

{
    my @TypesRe =
        ( [ text     => qr/(?:text|char(?:acter)?)\b/xism ],
          [ blob     => qr/blob\b|bytea\b/xism ],
          # The year type comes from MySQL
          [ integer  => qr/(?:int(?:eger)?\d*|year)\b/xism ],
          [ float    => qr/(?:float\d*|decimal|real|double|money|numeric)\b/xism ],
          # MySQL's timestamp is not always a datetime, it depends on
          # the length of the column, but this is the best _guess_.
          [ datetime => qr/datetime\b|^timestamp/xism ],
          [ date     => qr/date\b/xism ],
          [ time     => qr/^time|time\b/xism ],
          [ boolean  => qr/\bbool/xism ],
        );

    sub _guess_generic_type
    {
        my $self = shift;
        my $type = $self->type();

        for my $p (@TypesRe)
        {
            return $p->[0] if $type =~ /$p->[1]/;
        }

        return 'other';
    }
}

sub _clone
{
    my $self = shift;

    my %clone = %{$self};

    return bless \%clone, ref $self;
}

sub is_alias { return 0 }

sub alias
{
    my $self = shift;

    return Fey::Column::Alias->new( column => $self, @_ );
}

sub sql
{
    my $self = shift;
    my $dbh  = shift;

    return
        $dbh->quote_identifier( undef,
                                $self->_containing_table_name_or_alias(),
                                $self->name(),
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

    return $table->id() . q{.} . $self->name();
}

no Moose;
__PACKAGE__->meta()->make_immutable();

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

=head1 ROLES

This class does the C<Fey::Role::ColumnLike> role.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
