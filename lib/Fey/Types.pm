package Fey::Types;

use strict;
use warnings;

use List::AllUtils qw( all );
use overload ();
use Scalar::Util qw( blessed );

use Moose::Util::TypeConstraints;


subtype 'Fey.Type.GenericTypeName'
    => as 'Str'
    => where { /^(?:text|blob|integer|float|date|datetime|time|boolean|other)$/xism };

subtype 'Fey.Type.PosInteger'
    => as 'Int'
    => where { $_ > 0 };

subtype 'Fey.Type.PosOrZeroInteger'
    => as 'Int'
    => where { $_ >= 0 };

subtype 'Fey.Type.DefaultValue'
    => as 'Fey::Literal';

coerce 'Fey.Type.DefaultValue'
    => from 'Undef'
    => via { Fey::Literal::Null->new() }
    => from 'Value'
    => via { Fey::Literal->new_from_scalar($_) };

subtype 'Fey.Type.ArrayRefOfNamedObjectSets'
    => as 'ArrayRef'
    => where { return 1 unless @{$_};
               all { blessed $_ && $_->isa('Fey::NamedObjectSet') } @{$_} };

subtype 'Fey.Type.ArrayRefOfColumns'
    => as 'ArrayRef'
    => where { @{$_} >= 1 && all { $_ && $_->isa('Fey::Column') } @{$_} };

class_type('Fey::Column')
    unless find_type_constraint('Fey::Column');

role_type('Fey::Role::Named')
    unless find_type_constraint('Fey::Role::Named');

coerce 'Fey.Type.ArrayRefOfColumns'
    => from 'Fey::Column'
    => via { [ $_ ] };

subtype 'Fey.Type.FunctionArg'
    => as 'Object'
    => where { $_->does('Fey::Role::Selectable') };

coerce 'Fey.Type.FunctionArg'
    => from 'Undef'
    => via { Fey::Literal::Null->new() }
    => from 'Value'
    => via { Fey::Literal->new_from_scalar($_) };

{
    my $constraint = find_type_constraint('Fey.Type.FunctionArg');
    subtype 'Fey.Type.ArrayRefOfFunctionArgs'
        => as 'ArrayRef'
        => where { return 1 unless @{$_};
                   all { $constraint->check($_) } @{$_} };

    coerce 'Fey.Type.ArrayRefOfFunctionArgs'
        => from 'ArrayRef'
        => via { [ map { $constraint->coerce($_) } @{$_} ] };
}

subtype 'Fey.Type.LiteralTermArg'
    => as 'ArrayRef'
    => where { return unless $_ and @{$_};
               all { blessed($_)
                     ? $_->can('sql_or_alias') || overload::Overloaded( $_ )
                     : defined && ! ref } @{$_} };

coerce 'Fey.Type.LiteralTermArg'
    => from 'Value'
    => via { [ $_ ] };

for my $thing ( qw( Table Column ) )
{
    my $class = 'Fey::' . $thing;

    subtype 'Fey.Type.' . $thing . 'OrName'
        => as 'Item'
        => where { return unless defined $_;
                   return 1 unless blessed $_;
                   return $_->isa($class) };

    subtype 'Fey.Type.' . $thing . 'LikeOrName'
        => as 'Item'
        => where { return unless defined $_;
                   return 1 unless blessed $_;
                   return unless $_->can('does');
                   return $_->does( 'Fey::Role::' . $thing . 'Like' )  };
}

subtype 'Fey.Type.SelectElement'
    => as 'Item'
    => where {    ! blessed $_[0]
               || $_[0]->isa('Fey::Table')
               || $_[0]->isa('Fey::Table::Alias')
               || (    $_[0]->can('is_selectable')
                    && $_[0]->is_selectable() );
             };

subtype 'Fey.Type.ColumnWithTable'
    => as 'Object'
    => where {    $_[0]->isa('Fey::Column')
               && $_[0]->has_table() };

subtype 'Fey.Type.IntoElement'
    => as 'Object',
    => where { return
                   $_->isa('Fey::Table')
                   ||
                   (    $_->isa('Fey::Column')
                     && $_->table()
                     && ! $_->table()->is_alias()
                   );
             };

subtype 'Fey.Type.NullableInsertValue'
    => as 'Item'
    => where {    ! blessed $_
               || $_->isa('Fey::Literal')
               || $_->isa('Fey::Placeholder')
               || overload::Overloaded( $_ )
             };

subtype 'Fey.Type.NonNullableInsertValue'
    => as 'Defined'
    => where {    ! blessed $_
               || ( $_->isa('Fey::Literal') && ! $_->isa('Fey::Literal::Null') )
               || $_->isa('Fey::Placeholder')
               || overload::Overloaded( $_ )
             };

subtype 'Fey.Type.NullableUpdateValue'
    => as 'Item'
    => where {    ! blessed $_
               || $_->isa('Fey::Column')
               || $_->isa('Fey::Literal')
               || $_->isa('Fey::Placeholder')
               || overload::Overloaded( $_ )
             };

subtype 'Fey.Type.NonNullableUpdateValue'
    => as 'Defined'
    => where {    ! blessed $_
               || $_->isa('Fey::Column')
               || ( $_->isa('Fey::Literal') && ! $_->isa('Fey::Literal::Null') )
               || $_->isa('Fey::Placeholder')
               || overload::Overloaded( $_ )
             };

subtype 'Fey.Type.OrderByElement'
    => as 'Item'
    => where { if ( ! blessed $_ )
               {
                   return $_ =~ /^(?:asc|desc)$/i;
               }

               return 1
                   if    $_->can('is_orderable')
                      && $_->is_orderable();
             };

subtype 'Fey.Type.GroupByElement'
    => as 'Object'
    => where { return 1
                   if    $_->can('is_groupable')
                      && $_->is_groupable();
             };

subtype 'Fey.Type.OuterJoinType'
    => as 'Str',
    => where { return $_ =~ /^(?:full|left|right)$/ };

subtype 'Fey.Type.CanQuote'
    => as 'Item'
    => where { return $_->isa('DBI::db') || $_->can('quote') };

subtype 'Fey.Type.WhereBoolean'
    => as 'Str'
    => where { return $_ =~ /^(?:AND|OR)$/ };

subtype 'Fey.Type.WhereClauseSide'
    => as 'Item'
    => where { return 1 if ! defined $_;
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
