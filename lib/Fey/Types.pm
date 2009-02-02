package Fey::Types;

use strict;
use warnings;

use List::AllUtils qw( all );
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

no Moose::Util::TypeConstraints;

1;
