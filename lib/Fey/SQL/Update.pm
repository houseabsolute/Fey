package Fey::SQL::Update;

use strict;
use warnings;

use Fey::Exceptions qw( param_error );
use Fey::Validate
    qw( validate_pos
        SCALAR
        UNDEF
        OBJECT
        DBI_TYPE
      );

use Fey::Literal;
use overload ();
use Scalar::Util qw( blessed );

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

with 'Fey::Role::SQL::HasBindParams',
     'Fey::Role::SQL::HasWhereClause',
     'Fey::Role::SQL::HasOrderByClause',
     'Fey::Role::SQL::HasLimitClause';


{
    my $spec = { type => OBJECT,
                 callbacks =>
                 { 'is a (non-alias) table' =>
                   sub {    $_[0]->isa('Fey::Table')
                         && ! $_[0]->is_alias() },
                 },
               };

    sub update
    {
        my $self = shift;

        my $count = @_ ? @_ : 1;
        my (@tables) = validate_pos( @_, ($spec) x $count );

        $self->{tables} = \@tables;

        return $self;
    }
}

{
    my $column_spec = { type => OBJECT,
                        callbacks =>
                        { 'is a (non-alias) column' =>
                          sub {    $_[0]->isa('Fey::Column')
                                && $_[0]->table()
                                && ! $_[0]->is_alias() },
                        },
                      };

    my $nullable_col_value_type =
        { type      => SCALAR|UNDEF|OBJECT,
          callbacks =>
          { 'literal, placeholder, column, overloaded object, scalar, or undef' =>
            sub {    ! blessed $_[0]
                  || ( $_[0]->isa('Fey::Column') && ! $_[0]->is_alias() )
                  || $_[0]->isa('Fey::Literal')
                  || $_[0]->isa('Fey::Placeholder')
                  || defined $_[0] && overload::Overloaded( $_[0] ) },
          },
        };

    my $non_nullable_col_value_type =
        { type      => SCALAR|OBJECT,
          callbacks =>
          { 'literal, placeholder, column, overloaded object, or scalar' =>
            sub {    ! blessed $_[0]
                  || ( $_[0]->isa('Fey::Column') && ! $_[0]->is_alias() )
                  || ( $_[0]->isa('Fey::Literal') && ! $_[0]->isa('Fey::Literal::Null') )
                  || $_[0]->isa('Fey::Placeholder')
                  || overload::Overloaded( $_[0] ) },
          },
        };

    sub set
    {
        my $self = shift;

        if ( ! @_ || @_ % 2 )
        {
            my $count = @_;
            param_error
                "The set method expects a list of paired column objects and values but you passed $count parameters";
        }

        my @spec;
        for ( my $x = 0; $x < @_; $x += 2 )
        {
            push @spec, $column_spec;
            push @spec,
                ref $_[$x] && $_[$x]->is_nullable()
                ? $nullable_col_value_type
                : $non_nullable_col_value_type;
        }

        validate_pos( @_, @spec );

        for ( my $x = 0; $x < @_; $x += 2 )
        {
            my $val = $_[ $x + 1 ];

            $val .= ''
                if blessed $val && overload::Overloaded($val);

            if ( ! blessed $val )
            {
                if ( defined $val && $self->auto_placeholders() )
                {
                    push @{ $self->{bind_params} }, $val;

                    $val = Fey::Placeholder->new();
                }
                else
                {
                    $val = Fey::Literal->new_from_scalar($val );
                }
            }

            push @{ $self->{set} }, [ $_[$x], $val ];
        }

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
                 $self->_update_clause($dbh),
                 $self->_set_clause($dbh),
                 $self->_where_clause($dbh),
                 $self->_order_by_clause($dbh),
                 $self->_limit_clause($dbh),
               );
    }
}

sub _update_clause
{
    return 'UPDATE ' . $_[0]->_tables_subclause( $_[1] );
}

sub _tables_subclause
{
    return ( join ', ',
             map { $_[1]->quote_identifier( $_->name() ) }
             @{ $_[0]->{tables} }
           );
}

sub _set_clause
{
    my $self = shift;
    my $dbh  = shift;

    # SQLite objects when the table name is provided ("User"."email")
    # on the LHS of the set. I'm hoping that a DBMS which allows a
    # multi-table update also allows the table name in the LHS.
    my $col_quote = @{ $self->{tables} } > 1 ? '_name_and_table' : '_name';

    return ( 'SET '
             . ( join ', ',
                 map {   $self->$col_quote( $_->[0], $dbh )
                       . ' = '
                       . $_->[1]->sql( $dbh ) }
                 @{ $self->{set} }
               )
           );
}

sub _name_and_table
{
    return $_[1]->sql( $_[2] );
}

sub _name
{
    return $_[2]->quote_identifier( $_[1]->name() );
}

sub bind_params
{
    my $self = shift;

    return ( @{ $self->{bind_params} || [] },
             $self->_where_clause_bind_params(),
           );
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Fey::SQL::Update - Represents a UPDATE query

=head1 SYNOPSIS

  my $sql = Fey::SQL->new_update();

  # UPDATE Part
  #    SET quantity = 10
  #  WHERE part_id IN (1, 5)
  $sql->update($Part);
  $sql->set( $quantity, 10 );
  $sql->where( $part_id, 'IN', 1, 5 );

  print $sql->sql($dbh);

=head1 DESCRIPTION

This class represents a C<UPDATE> query.

=head1 METHODS

This class provides the following methods:

=head2 Constructor

To construct an object of this class, call C<< $query->update() >> on
a C<Fey::SQL> object.

=head2 $update->update()

This method specifies the C<UPDATE> clause of the query. It expects
one or more L<Fey::Table> objects (not aliases). Most RDBMS
implementations only allow for a single table here, but some (like
MySQL) do allow for multi-table updates.

=head2 $update->set(...)

This method takes a list of key/value pairs. The keys should be column
objects, and the value can be one of the following:

=over 4

=item * a plain scalar, including undef

This will be passed to C<< Fey::Literal->new_from_scalar() >>.

=item * C<Fey::Literal> object

=item * C<Fey::Column> object

A column alias cannot be used.

=item * C<Fey::Placeholder> object

=back

=head2 $update->where(...)

See the L<Fey::SQL section on WHERE Clauses|Fey::SQL/WHERE Clauses>
for more details.

=head2 $update->order_by(...)

See the L<Fey::SQL section on ORDER BY Clauses|Fey::SQL/ORDER BY
Clauses> for more details.

=head2 $update->limit(...)

See the L<Fey::SQL section on LIMIT Clauses|Fey::SQL/LIMIT Clauses>
for more details.

=head2 $update->sql($dbh)

Returns the full SQL statement which this object represents. A DBI
handle must be passed so that identifiers can be properly quoted.

=head2 $update->bind_params()

See the L<Fey::SQL section on Bind Parameters|Fey::SQL/Bind
Parameters> for more details.

=head1 ROLES

This class does
C<Fey::Role::SQL::HasWhereClause>,
C<Fey::Role::SQL::HasOrderByClause>, and
C<Fey::Role::SQL::HasLimitClause> roles.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
