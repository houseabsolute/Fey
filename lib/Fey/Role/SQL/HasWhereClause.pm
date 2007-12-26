package Fey::Role::SQL::HasWhereClause;

use strict;
use warnings;

use Moose::Role;

use Fey::Exceptions qw( param_error );

use Fey::SQL::Fragment::Where::Boolean;
use Fey::SQL::Fragment::Where::Comparison;
use Fey::SQL::Fragment::Where::SubgroupStart;
use Fey::SQL::Fragment::Where::SubgroupEnd;


sub where
{
    my $self = shift;

    $self->_condition( 'where', @_ );

    return $self;
}


{
    my %dispatch = ( 'and' => '_and',
                     'or'  => '_or',
                     '('   => '_subgroup_start',
                     ')'   => '_subgroup_end',
                   );
    sub _condition
    {
        my $self = shift;
        my $key  = shift;

        if ( @_ == 1 )
        {
            if ( my $meth = $dispatch{ lc $_[0] } )
            {
                $self->$meth($key);
                return;
            }
            else
            {
                param_error
                    qq|Cannot pass one argument to $key() unless it is one of "and", "or", "(", or ")".|;
            }
        }

        if ( @{ $self->{$key} || [] }
             && ! (    $self->{$key}[-1]->isa('Fey::SQL::Fragment::Where::Boolean')
                    || $self->{$key}[-1]
                            ->isa('Fey::SQL::Fragment::Where::SubgroupStart')
                  )
           )
        {
            $self->_and($key);
        }

        push @{ $self->{$key} },
            Fey::SQL::Fragment::Where::Comparison->new(@_);
    }
}

sub _and
{
    my $self = shift;
    my $key  = shift;

    push @{ $self->{$key} },
        Fey::SQL::Fragment::Where::Boolean->new( 'AND' );

    return $self;
}

sub _or
{
    my $self = shift;
    my $key  = shift;

    push @{ $self->{$key} },
        Fey::SQL::Fragment::Where::Boolean->new( 'OR' );

    return $self;
}

sub _subgroup_start
{
    my $self = shift;
    my $key  = shift;

    push @{ $self->{$key} },
        Fey::SQL::Fragment::Where::SubgroupStart->new();

    return $self;
}

sub _subgroup_end
{
    my $self = shift;
    my $key  = shift;

    push @{ $self->{$key} },
        Fey::SQL::Fragment::Where::SubgroupEnd->new();

    return $self;
}

sub _where_clause
{
    return unless $_[0]->{where};

    my $sql = '';
    $sql = 'WHERE '
        unless $_[2];

    return ( $sql
             . ( join ' ',
                 map { $_->sql( $_[1] ) }
                 @{ $_[0]->{where} }
               )
           );
}


1;

__END__

=head1 NAME

Fey::Role::SQL::HasWhereClause - A role for queries which can include a WHERE clause

=head1 SYNOPSIS

  use Moose;

  with 'Fey::Role::SQL::HasWhereClause';

=head1 DESCRIPTION

Classes which do this role represent a query which can include a
C<WHERE> clause.

=head1 METHODS

This role provides the following methods:

=head2 $query->where()

See the L<Fey::SQL section on WHERE Clauses|Fey::SQL/WHERE Clauses>
for more details.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
