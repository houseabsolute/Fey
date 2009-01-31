package Fey::SQL::Insert;

use strict;
use warnings;

use Fey::Validate
    qw( validate
        validate_pos
        SCALAR
        UNDEF
        OBJECT
        DBI_TYPE
      );

use overload ();
use Scalar::Util qw( blessed );

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

with 'Fey::Role::SQL::HasBindParams';


sub insert { return $_[0] }

{
    my $spec = { type => OBJECT,
                 callbacks =>
                 { 'is a (non-alias) table or column with a table' =>
                   sub { (    $_[0]->isa('Fey::Table')
                           && ! $_[0]->is_alias()
                         )
                         ||
                         ( $_[0]->isa('Fey::Column')
                           && $_[0]->table()
                           && ! $_[0]->is_alias()
                           && ! $_[0]->table()->is_alias()
                         )
                       }
                 },
               };

    my $nullable_col_value_type =
    { type      => SCALAR|UNDEF|OBJECT,
      callbacks =>
      { 'literal, placeholder, scalar, overloaded object, or undef' =>
        sub {    ! blessed $_[0]
              || $_[0]->isa('Fey::Literal')
              || $_[0]->isa('Fey::Placeholder')
              || overload::Overloaded( $_[0] ) }
      },
    };

    my $non_nullable_col_value_type =
        { type      => SCALAR|OBJECT,
          callbacks =>
          { 'literal, placeholder,, scalar, or overloaded object' =>
            sub {    ! blessed $_[0]
                  || ( $_[0]->isa('Fey::Literal') && ! $_[0]->isa('Fey::Literal::Null') )
                  || $_[0]->isa('Fey::Placeholder')
                  || overload::Overloaded( $_[0] ) }
          },
        };

    sub into
    {
        my $self = shift;
        my $count = @_ ? scalar @_ : 1;

        my @cols;
        for ( validate_pos( @_, ($spec) x $count ) )
        {
            push @cols, $_->isa('Fey::Table')
                ? $_->columns
                : $_;
        }

        $self->{columns} = \@cols;

        for my $col ( @{ $self->{columns} } )
        {
            $self->{values_spec}{ $col->name() } =
                $col->is_nullable()
                ? $nullable_col_value_type
                : $non_nullable_col_value_type;
        }

        return $self;
    }
}

{
    sub values
    {
        my $self = shift;

        my %vals = validate( @_, $self->{values_spec} );

        for ( values %vals )
        {
            $_ .= ''
                if blessed $_ && overload::Overloaded($_);

            if ( ! blessed $_ )
            {
                if ( defined $_ && $self->auto_placeholders() )
                {
                    push @{ $self->{bind_params} }, $_;

                    $_ = Fey::Placeholder->new();
                }
                else
                {
                    $_ = Fey::Literal->new_from_scalar($_);
                }
            }
        }

        push @{ $self->{values} }, \%vals;

        return $self;
    }
}

{
    my @spec = ( DBI_TYPE );

    sub sql
    {
        my $self  = shift;
        my ($dbh) = validate_pos( @_, @spec );

        return ( join ' ',
                 $self->insert_clause($dbh),
                 $self->columns_clause($dbh),
                 $self->values_clause($dbh),
               );
    }
}

sub insert_clause
{
    return
        ( 'INSERT INTO '
          . $_[1]->quote_identifier( $_[0]->{columns}[0]->table()->name() )
        );
}

sub columns_clause
{
    return
        ( '('
          . ( join ', ',
              map { $_[1]->quote_identifier( $_->name() ) }
              @{ $_[0]->{columns} }
            )
          . ')'
        );
}

sub values_clause
{
    my $self = shift;
    my $dbh  = shift;

    my @v;
    for my $vals ( @{ $self->{values} } )
    {
        my $v = '(';

        $v .=
            ( join ', ',
              map { $vals->{ $_->name() }->sql($dbh) }
              @{ $self->{columns} }
           );

        $v .= ')';

        push @v, $v;
    }

    return 'VALUES ' . join ',', @v;
}

sub bind_params
{
    my $self = shift;

    return @{ $self->{bind_params} || [] };
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Fey::SQL::Insert - Represents a INSERT query

=head1 SYNOPSIS

  my $sql = Fey::SQL->new_insert();

  # INSERT INTO Part
  #             (part_id, name, quantity)
  #      VALUES
  #             (?, ?, ?)
  $sql->insert()->into($Part);

  my $ph = Fey::Placeholder->new();

  $sql->values( part_id  => $ph,
                name     => $ph,
                quantity => $ph,
              );

  print $sql->sql($dbh);

=head1 DESCRIPTION

This class represents a C<INSERT> query.

=head1 METHODS

This class provides the following methods:

=head2 Constructor

To construct an object of this class, call C<< $query->insert() >> on
a C<Fey::SQL> object.

=head2 $insert->insert()

This method is basically a no-op that exists to so that L<Fey::SQL>
has something to call after it constructs an object in this class.

=head2 $insert->into()

This method specifies the C<INTO> clause of the query. It expects a
list of L<Fey::Column> and/or L<Fey::Table> objects, but not aliases.

If you pass a table object, then the C<INTO> will include all of that
table's columns, in the order returned by the C<< $table->columns() >>
method.

Most RDBMS implementations only allow for a single table here, but
some (like MySQL) do allow for multi-table inserts.

=head2 $insert->values(...)

This method takes a hash reference where the keys are column names,
and values are the value to be inserted for that column. Each value
can be of the following:

=over 4

=item * a plain scalar, including undef

This will be passed to C<< Fey::Literal->new_from_scalar() >>.

=item * C<Fey::Literal> object

=item * C<Fey::Placeholder> object

=back

=head2 $insert->sql()

Returns the full SQL statement which this object represents. A DBI
handle must be passed so that identifiers can be properly quoted.

=head2 $insert->bind_params()

See the L<Fey::SQL section on Bind Parameters|Fey::SQL/Bind
Parameters> for more details.

=head2 $insert->insert_clause()

Returns the C<INSERT INTO> clause portion of the SQL statement as a
string (just the tables).

=head2 $insert->columns_clause()

Returns the portion of the SQL statement containing the columns for
which values are being inserted as a string.

=head2 $insert->values_clause()

Returns the C<VALUES> clause portion of the SQL statement as a string.

=head1 ROLES

This class does C<Fey::Role::SQL::HasBindParams> role.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
