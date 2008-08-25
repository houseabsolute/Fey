package Fey::SQL::Fragment::Where::Comparison;

use strict;
use warnings;


use Fey::Exceptions qw( param_error );
use Fey::Validate
    qw( validate_pos
        SCALAR_TYPE
        UNDEF
        SCALAR
        OBJECT
      );
use Scalar::Util qw( blessed );

use Fey::SQL::Fragment::SubSelect;
use Fey::Literal;
use Fey::Placeholder;
use overload ();

use constant LHS         => 0;
use constant COMP        => 1;
use constant RHS         => 2;
use constant BIND_PARAMS => 3;

our $eq_comp_re = qr/^(?:=|!=|<>)$/;
our $in_comp_re = qr/^(?:not\s+)?in$/i;

{
    my $comparable = 
        { type      => UNDEF|SCALAR|OBJECT,
          'is comparable' =>
            sub {    ! blessed $_[0]
                  || (    $_[0]->can('is_comparable')
                       && $_[0]->is_comparable()
                     )
                  || overload::Overloaded( $_[0] )
                },
        };

    my $operator = SCALAR_TYPE;

    sub new
    {
        my $class            = shift;
        my $auto_placeholders = shift;

        my $rhs_count = @_ - 2;
        $rhs_count = 1 if $rhs_count < 1;

        my ( $lhs, $comp, @rhs ) =
            validate_pos( @_, $comparable, $operator, ($comparable) x $rhs_count );

        my @bind;
        for ( $lhs, @rhs )
        {
            if ( blessed $_ && $_->can('is_comparable') )
            {
                if ( $_->isa('Fey::SQL::Select') )
                {
                    push @bind, $_->bind_params();

                    $_ = Fey::SQL::Fragment::SubSelect->new($_);
                }

                next;
            }

            if ( blessed $_ )
            {
                if ( overload::Overloaded($_) )
                {
                    # This "de-references" the value, which will make
                    # things simpler when we pass it to DBI, test
                    # code, etc. It works fine with numbers, more or
                    # less (see Fey::Literal).
                    $_ .= '';
                }
                else
                {
                    param_error "Cannot pass an object as part of a where clause comparison"
                                . " unless that object does Fey::Role::Comparable or is overloaded.";
                }
            }

            if ( defined $_ && $auto_placeholders )
            {
                push @bind, $_;

                $_ = Fey::Placeholder->new();
            }
            else
            {
                $_ = Fey::Literal->new_from_scalar($_);
            }

        }

        if ( grep { $_->isa('Fey::SQL::Fragment::SubSelect') } @rhs )
        {
            param_error "Cannot use a subselect on the right-hand side with $comp"
                unless $comp =~ /$in_comp_re/;
        }

        if ( lc $comp eq 'between' )
        {
            param_error "The BETWEEN operator requires two arguments"
                unless @rhs == 2;
        }

        if ( @rhs > 1 )
        {
            param_error "Cannot pass more than one right-hand side argument with $comp"
                unless $comp =~ /^(?:$in_comp_re|between)$/i;
        }

        return bless [ $lhs, $comp, \@rhs, \@bind ], $class;
    }
}

sub sql
{
    my $sql = $_[0][LHS]->sql_or_alias( $_[1] );

    if (    $_[0][COMP] =~ $eq_comp_re
         && $_[0][RHS][0]->isa('Fey::Literal::Null') )
    {
        return
            (   $sql
              . (   $_[0][COMP] eq '='
                  ? ' IS NULL'
                  : ' IS NOT NULL'
                )
            );
    }

    if ( lc $_[0][COMP] eq 'between' )
    {
        return
            (   $sql
              . ' BETWEEN '
              . $_[0][RHS][0]->sql_or_alias( $_[1] )
              . ' AND '
              . $_[0][RHS][1]->sql_or_alias( $_[1] )
            );
    }

    if ( $_[0][COMP] =~ $in_comp_re )
    {
        return
            (   $sql
              . ' '
              . ( uc $_[0][COMP] )
              . ' ('
              . ( join ', ',
                  map { $_->sql_or_alias( $_[1] ) }
                  @{ $_[0][RHS] }
                )
              . ')'
            );
    }

    return
        (   $sql
          . ' '
          . $_[0][COMP]
          . ' '
          . $_[0][RHS][0]->sql_or_alias( $_[1] )
        );
}

sub bind_params
{
    return @{ $_[0]->[BIND_PARAMS] };
}


1;

__END__

=head1 NAME

Fey::SQL::Fragment::Where::Boolean - Represents a comparison in a WHERE clause

=head1 DESCRIPTION

This class represents a comparison in a WHERE clause.

It is intended solely for internal use in L<Fey::SQL> objects, and as
such is not intended for public use.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
