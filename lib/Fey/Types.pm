package Fey::Types;

use strict;
use warnings;

our $VERSION = '0.34';

use List::AllUtils qw( all );
use overload ();
use Scalar::Util qw( blessed );

use Moose::Util::TypeConstraints;


subtype 'Fey::Types::GenericTypeName'
    => as 'Str'
    => where { /^(?:text|blob|integer|float|date|datetime|time|boolean|other)$/xism };

subtype 'Fey::Types::PosInteger'
    => as 'Int'
    => where { $_ > 0 };

subtype 'Fey::Types::PosOrZeroInteger'
    => as 'Int'
    => where { $_ >= 0 };

subtype 'Fey::Types::DefaultValue'
    => as role_type('Fey::Role::IsLiteral');

coerce 'Fey::Types::DefaultValue'
    => from 'Undef'
    => via { Fey::Literal::Null->new() }
    => from 'Value'
    => via { Fey::Literal->new_from_scalar($_) };

subtype 'Fey::Types::ArrayRefOfNamedObjectSets'
    => as 'ArrayRef'
    => where { return 1 unless @{$_};
               all { blessed $_ && $_->isa('Fey::NamedObjectSet') } @{$_} };

subtype 'Fey::Types::ArrayRefOfColumns'
    => as 'ArrayRef'
    => where { @{$_} >= 1 && all { $_ && $_->isa('Fey::Column') } @{$_} };

class_type('Fey::Column')
    unless find_type_constraint('Fey::Column');

role_type('Fey::Role::Named')
    unless find_type_constraint('Fey::Role::Named');

coerce 'Fey::Types::ArrayRefOfColumns'
    => from 'Fey::Column'
    => via { [ $_ ] };

subtype 'Fey::Types::FunctionArg'
    => as 'Object'
    => where { $_->can('does') && $_->does('Fey::Role::Selectable') };

coerce 'Fey::Types::FunctionArg'
    => from 'Undef'
    => via { Fey::Literal::Null->new() }
    => from 'Value'
    => via { Fey::Literal->new_from_scalar($_) };

{
    my $constraint = find_type_constraint('Fey::Types::FunctionArg');
    subtype 'Fey::Types::ArrayRefOfFunctionArgs'
        => as 'ArrayRef'
        => where { return 1 unless @{$_};
                   all { $constraint->check($_) } @{$_} };

    coerce 'Fey::Types::ArrayRefOfFunctionArgs'
        => from 'ArrayRef'
        => via { [ map { $constraint->coerce($_) } @{$_} ] };
}

subtype 'Fey::Types::LiteralTermArg'
    => as 'ArrayRef'
    => where { return unless $_ and @{$_};
               all { blessed($_)
                     ? $_->can('sql_or_alias') || overload::Overloaded( $_ )
                     : defined && ! ref } @{$_} };

coerce 'Fey::Types::LiteralTermArg'
    => from 'Value'
    => via { [ $_ ] };

for my $thing ( qw( Table Column ) )
{
    my $class = 'Fey::' . $thing;

    subtype 'Fey::Types::' . $thing . 'OrName'
        => as 'Item'
        => where { return unless defined $_;
                   return 1 unless blessed $_;
                   return $_->isa($class) };

    subtype 'Fey::Types::' . $thing . 'LikeOrName'
        => as 'Item'
        => where { return unless defined $_;
                   return 1 unless blessed $_;
                   return unless $_->can('does');
                   return $_->can('does') && $_->does( 'Fey::Role::' . $thing . 'Like' )  };
}

subtype 'Fey::Types::SetOperationArg'
    => as role_type('Fey::Role::SQL::ReturnsData');

subtype 'Fey::Types::SelectElement'
    => as 'Item'
    => where {    ! blessed $_[0]
               || $_[0]->isa('Fey::Table')
               || $_[0]->isa('Fey::Table::Alias')
               || (    $_[0]->can('is_selectable')
                    && $_[0]->is_selectable() );
             };

subtype 'Fey::Types::ColumnWithTable'
    => as 'Object'
    => where {    $_[0]->isa('Fey::Column')
               && $_[0]->has_table() };

subtype 'Fey::Types::IntoElement'
    => as 'Object',
    => where { return
                   $_->isa('Fey::Table')
                   ||
                   (    $_->isa('Fey::Column')
                     && $_->table()
                     && ! $_->table()->is_alias()
                   );
             };

subtype 'Fey::Types::NullableInsertValue'
    => as 'Item'
    => where {    ! blessed $_
               || ( $_->can('does') && $_->does('Fey::Role::IsLiteral') )
               || $_->isa('Fey::Placeholder')
               || overload::Overloaded( $_ )
             };

subtype 'Fey::Types::NonNullableInsertValue'
    => as 'Defined'
    => where {    ! blessed $_
               || ( $_->can('does') && $_->does('Fey::Role::IsLiteral') && ! $_->isa('Fey::Literal::Null') )
               || $_->isa('Fey::Placeholder')
               || overload::Overloaded( $_ )
             };

subtype 'Fey::Types::NullableUpdateValue'
    => as 'Item'
    => where {    ! blessed $_
               || $_->isa('Fey::Column')
               || ( $_->can('does') && $_->does('Fey::Role::IsLiteral') )
               || $_->isa('Fey::Placeholder')
               || overload::Overloaded( $_ )
             };

subtype 'Fey::Types::NonNullableUpdateValue'
    => as 'Defined'
    => where {    ! blessed $_
               || $_->isa('Fey::Column')
               || ( $_->can('does') && $_->does('Fey::Role::IsLiteral') && ! $_->isa('Fey::Literal::Null') )
               || $_->isa('Fey::Placeholder')
               || overload::Overloaded( $_ )
             };

subtype 'Fey::Types::OrderByElement'
    => as 'Item'
    => where { if ( ! blessed $_ )
               {
                   return $_ =~ /^(?:asc|desc)(?: nulls (?:last|first))?$/i;
               }

               return 1
                   if    $_->can('is_orderable')
                      && $_->is_orderable();
             };

subtype 'Fey::Types::GroupByElement'
    => as 'Object'
    => where { return 1
                   if    $_->can('is_groupable')
                      && $_->is_groupable();
             };

subtype 'Fey::Types::OuterJoinType'
    => as 'Str',
    => where { return $_ =~ /^(?:full|left|right)$/ };

subtype 'Fey::Types::CanQuote'
    => as 'Item'
    => where { return $_->isa('DBI::db') || $_->can('quote') };

subtype 'Fey::Types::WhereBoolean'
    => as 'Str'
    => where { return $_ =~ /^(?:AND|OR)$/ };

subtype 'Fey::Types::WhereClauseSide'
    => as 'Item'
    => where { return 1 if ! defined $_;
               return 0 if ref $_ && ! blessed $_;
               return 1 unless blessed $_;
               return 1 if overload::Overloaded($_);

               return 1
                   if    $_->can('is_comparable')
                      && $_->is_comparable();
             };

no Moose::Util::TypeConstraints;

1;

__END__

=head1 NAME

Fey::Types - Types for use in Fey

=head1 DESCRIPTION

This module defines a whole bunch of types used by the Fey core
classes. None of these types are documented for external use at the
present, though that could change in the future.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
