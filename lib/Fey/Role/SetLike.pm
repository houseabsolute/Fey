package Fey::Role::SetLike;

use strict;
use warnings;

use MooseX::Role::Parameterized;
use MooseX::Params::Validate qw( pos_validated_list );

parameter keyword =>
(
    isa => 'Str',
    required => 1,
);

role {
    my $p = shift;

    my $name = lc($p->keyword);

    with 'Fey::Role::SQL::HasOrderByClause',
         'Fey::Role::SQL::HasLimitClause';

    has 'is_all' =>
        ( is      => 'rw',
          isa     => 'Bool',
          default => 0,
          writer  => '_set_is_all',
        );

    has '_set_element' =>
        ( metaclass => 'Collection::Array',
          is        => 'ro',
          isa       => 'ArrayRef',
          default   => sub { [] },
          provides  => { push     => '_add_set_elements',
                         elements => '_set_elements',
                       },
          init_arg  => undef,
        );

    my $clause_method = $name . '_clause';

    method 'all' => sub
    {
        $_[0]->_set_is_all(1);
        return $_[0];
    };

    method 'keyword_clause' => sub
    {
        my $self = shift;

        my $sql = uc($name);
        $sql .= ' ALL' if $self->is_all;
        return $sql;
    };

    method $name => sub
    {
        my $self = shift;

        my $count = @_;
        $count = 2 if $count < 2;

        my (@set) = 
            pos_validated_list( \@_,
                                ( ( { isa => 'Fey::SQL::Select' } ) x $count ),
                                MX_PARAMS_VALIDATE_NO_CACHE => 1,
                              );

        $self->_add_set_elements(@set);

        return $self;
    };

    method $clause_method => sub
    {
        my $self = shift;
        my $dbh  = shift;

        return
            ( join ' ' . $self->keyword_clause($dbh) . ' ',
              map { '(' . $_->sql($dbh) . ')' }
              $self->_set_elements
            );
    };

    method 'sql' => sub
    {
        my $self = shift;
        my $dbh  = shift;

        return
            ( join ' ',
              $self->$clause_method($dbh),
              $self->order_by_clause($dbh),
              $self->limit_clause($dbh),
            );
    };

    method 'bind_params' => sub
    {
        my $self = shift;
        return 
            ( map { $_->bind_params } $self->_set_elements
            );
    };
};

no MooseX::Role::Parameterized;

1;

__END__

=head1 NAME

Fey::Role::SetLike - A role for things that are like a set operation

=head1 SYNOPSIS

  use Moose;

  with 'Fey::Role::SetLike' => { keyword => 'STUFF' };

=head1 DESCRIPTION

Stuff.

=head1 AUTHOR

Hans Dieter Pearcey <hdp.cpan.fey@weftsoar.net>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
