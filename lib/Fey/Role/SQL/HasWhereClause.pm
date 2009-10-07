package Fey::Role::SQL::HasWhereClause;

use strict;
use warnings;

our $VERSION = '0.33';

use Fey::Exceptions qw( param_error );

use Fey::SQL::Fragment::Where::Boolean;
use Fey::SQL::Fragment::Where::Comparison;
use Fey::SQL::Fragment::Where::SubgroupStart;
use Fey::SQL::Fragment::Where::SubgroupEnd;

use Moose::Role;

has '_where' =>
    ( traits   => [ 'Array' ],
      is       => 'bare',
      isa      => 'ArrayRef',
      default  => sub { [] },
      handles  => { _add_where_element  => 'push',
                    _has_where_elements => 'count',
                    _last_where_element => [ 'get', -1 ],
                    _where              => 'elements',
                  },
      init_arg => undef,
    );


sub where
{
    my $self = shift;

    $self->_condition( 'where', @_ );

    return $self;
}

# Just some sugar
sub and
{
    my $self = shift;

    return $self->where(@_);
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

        $self->_add_and_if_needed($key);

        my $add_method = '_add_' . $key . '_element';
        $self->$add_method
            ( Fey::SQL::Fragment::Where::Comparison->new( $self->auto_placeholders(), @_ ) );
    }
}

sub _add_and_if_needed
{
    my $self = shift;
    my $key  = shift;

    my $has_method = '_has_' . $key . '_elements';

    return unless $self->$has_method();

    my $last_method = '_last_' . $key . '_element';
    my $last = $self->$last_method();

    return if $last->isa('Fey::SQL::Fragment::Where::Boolean');
    return if $last->isa('Fey::SQL::Fragment::Where::SubgroupStart');

    $self->_and($key);
}

sub _and
{
    my $self = shift;
    my $key  = shift;

    my $add_method = '_add_' . $key . '_element';
    $self->$add_method
        ( Fey::SQL::Fragment::Where::Boolean->new( comparison => 'AND' ) );

    return $self;
}

sub _or
{
    my $self = shift;
    my $key  = shift;

    my $add_method = '_add_' . $key . '_element';
    $self->$add_method
        ( Fey::SQL::Fragment::Where::Boolean->new( comparison => 'OR' ) );

    return $self;
}

sub _subgroup_start
{
    my $self = shift;
    my $key  = shift;

    $self->_add_and_if_needed($key);

    my $add_method = '_add_' . $key . '_element';
    $self->$add_method
        ( Fey::SQL::Fragment::Where::SubgroupStart->new() );

    return $self;
}

sub _subgroup_end
{
    my $self = shift;
    my $key  = shift;

    my $add_method = '_add_' . $key . '_element';
    $self->$add_method
        ( Fey::SQL::Fragment::Where::SubgroupEnd->new() );

    return $self;
}

sub where_clause
{
    my $self       = shift;
    my $dbh        = shift;
    my $skip_where = shift;

    return unless $self->_has_where_elements();

    my $sql = '';
    $sql = 'WHERE '
        unless $skip_where;

    return ( $sql
             . ( join ' ',
                 map { $_->sql($dbh) }
                 $self->_where()
               )
           );
}

sub bind_params
{
    my $self = shift;

    return
        ( map { $_->bind_params() }
          grep { $_->can('bind_params') }
          $self->_where()
        );
}

no Moose::Role;

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

=head2 $query->and()

See the L<Fey::SQL section on WHERE Clauses|Fey::SQL/WHERE Clauses>
for more details.

=head2 $query->where_clause()

Returns the C<WHERE> clause portion of the SQL statement as a string.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
