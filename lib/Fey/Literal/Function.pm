package Fey::Literal::Function;

use strict;
use warnings;

use base 'Fey::Literal';
__PACKAGE__->mk_ro_accessors
    ( qw( alias_name function ) );

use Class::Trait ( 'Fey::Trait::Selectable' );
use Class::Trait ( 'Fey::Trait::Comparable' );
use Class::Trait ( 'Fey::Trait::Groupable' => { exclude => 'is_groupable' } );
use Class::Trait ( 'Fey::Trait::Orderable' );

use Fey::Validate
    qw( validate_pos
        SCALAR_TYPE
        SCALAR
        OBJECT
      );

use Scalar::Util qw( blessed );


{
    my $func_spec = SCALAR_TYPE;
    my $arg_spec  = { type      => SCALAR|OBJECT,
                      callbacks =>
                      { 'is scalar, column (with table) or literal'
                        => sub {    ! blessed $_[0]
                                 || (    $_[0]->can('is_selectable')
                                      && $_[0]->is_selectable() ) }
                      },
                    };
    sub new
    {
        my $class = shift;
        my ( $func, @args ) = validate_pos( @_, $func_spec, ($arg_spec) x (@_ - 1) );

        my $self = bless { function => $func }, $class;
        $self->{args} =
            [ map { blessed $_ ? $_ : Fey::Literal->new_from_scalar($_) } @args ];

        return $self;
    }
}

sub args { @{ $_[0]->{args} } }

sub sql
{
    my $sql = $_[0]->function();
    $sql .= '(';

    $sql .=
        ( join ', ',
          map { $_->sql( $_[1] ) }
          $_[0]->args()
        );
    $sql .= ')';
}

sub sql_with_alias
{
    $_[0]->_make_alias()
        unless $_[0]->alias_name();

    my $sql = $_[0]->sql( $_[1] );

    $sql .= ' AS ';
    $sql .= $_[0]->alias_name();

    return $sql;
}

{
    my $Number = 0;
    sub _make_alias
    {
        $_[0]->{alias_name} = 'FUNCTION' . $Number++;
    }
}

sub sql_or_alias
{
    return $_[1]->quote_identifier( $_[0]->alias_name() )
        if $_[0]->alias_name();

    return $_[0]->sql( $_[1] );
}

sub is_groupable { $_[0]->alias_name() ? 1 : 0 }


1;

__END__

=head1 NAME

Fey::Literal::Function - Represents a literal function in a SQL statement

=head1 SYNOPSIS

  my $function = Fey::Literal::Function->new( 'LENGTH', $column );

=head1 DESCRIPTION

This class represents a literal function in a SQL statement, such as
C<NOW()> or C<LENGTH(User.username)>.

=head1 INHERITANCE

This module is a subclass of C<Fey::Literal>.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Literal::Function->new( $function, @args )

This method creates a new C<Fey::Literal::Function> object.

It requires at least one argument, which is the name of the SQL
function that this literal represents. It can accept any number of
additional optional arguments. These arguments must be either scalars,
literals, or columns which belong to a table.

Any scalars passed in as arguments will be passed in turn to C<<
Fey::Literal->new_from_scalar() >>.

=head2 $function->function()

The function's name, as passed to the constructor.

=head2 $function->args()

Returns the function's arguments, as passed to the constructor.

=head2 $function->sql()

=head2 $function->sql_with_alias()

=head2 $function->sql_or_alias()

Returns the appropriate SQL snippet.

Calling C<< $function->sql_with_alias() >> causes a unique alias for
the function to be created.

=head1 TRAITS

This class does the C<Fey::Trait::Selectable>,
C<Fey::Trait::Comparable>, C<Fey::Trait::Groupable>, and
C<Fey::Trait::Orderable> traits.

This class overrides the C<is_groupable()> and C<is_orderable()>
methods so that they only return true if the C<<
$function->sql_with_alias() >> has been called previously. This
function is called when a function is used in the C<SELECT> clause of
a query. A function must be used in a C<SELECT> in order to be used in
a C<GROUP BY> or C<ORDER BY> clause.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
