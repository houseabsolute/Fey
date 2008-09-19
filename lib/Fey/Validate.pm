package Fey::Validate;

use strict;
use warnings;

use base 'Exporter';

use Params::Validate qw(:types);
use Scalar::Util qw( blessed );
use Fey::Exceptions qw( param_error );


my %Types;
BEGIN
{
    %Types =
        ( POS_INTEGER_TYPE =>
              { type      => SCALAR,
                callbacks =>
                { 'is a positive integer' =>
                  sub { $_[0] =~ qr/^\d+$/ && $_[0] > 0 }
                }
              },

          POS_OR_ZERO_INTEGER_TYPE =>
              { type      => SCALAR,
                callbacks =>
                { 'is a positive or zero integer' =>
                  sub { $_[0] =~ qr/^\d+$/ && $_[0] >= 0 }
                }
              },

          DBI_TYPE =>
              { type => SCALAR | OBJECT,
                isa  => 'DBI::db',
              },

          NAMED_OBJECT_TYPE =>
              { type => OBJECT,
                can  => 'name',
              },

          ARRAYREF_OR_SCALAR_TYPE =>
              { type      => ARRAYREF | SCALAR,
                callbacks =>
                { 'is a scalar or arrayref with elements' =>
                  sub { ! ref $_[0] || @{ $_[0] } }
                },
              },
        );


    for my $t ( grep { /^[A-Z]+$/ } @Params::Validate::EXPORT_OK )
    {
        my $name = $t . '_TYPE';
        $Types{$name} = { type => eval $t };
    }

    for my $class ( qw( Schema Table Column FK Query Literal ) )
    {
        $Types{ uc $class . '_TYPE' } = { isa => "Fey::${class}" };
    }

    for my $class ( qw( Table Column ) )
    {
        $Types{ uc $class . '_OR_NAME_TYPE' } =
            { type      => SCALAR|OBJECT,
              callbacks =>
              { "is a Fey::$class object or name" =>
                sub { ! blessed $_[0] || $_[0]->isa("Fey::$class") },
              },
            };
    }

    $Types{TABLE_OR_NAME_OR_ALIAS_TYPE} =
    { type      => SCALAR|OBJECT,
      callbacks =>
      { "is a Fey::Table, Fey::Table::Alias, or name" =>
        sub { ! blessed $_[0] || $_[0]->isa("Fey::Table") || $_[0]->isa("Fey::Table::Alias") },
      },
    };

    for my $class ( qw( Select Insert Update Delete ) )
    {
        $Types{ uc $class . '_TYPE' } = { isa => "Fey::SQL::${class}" };
    }

    for my $t ( keys %Types )
    {
        my %t = %{ $Types{$t} };
        my $sub = sub { param_error "Invalid additional args for $t: [@_]" if @_ % 2;
                        return { %t, @_ } };

        no strict 'refs';
        *{$t} = $sub;
    }
}

our %EXPORT_TAGS = ( types => [ keys %Types ] );
our @EXPORT_OK = keys %Types;

my %MyExports = map { $_ => 1 }
    @EXPORT_OK,
    map { ":$_" } keys %EXPORT_TAGS;

sub import
{
    my $class = shift;

    my $caller = caller;

    my @pv_export = grep { ! $MyExports{$_} } @_;

    {
        eval <<"EOF";
package $caller;

use Params::Validate qw(@pv_export);
Params::Validate::set_options( on_fail => \\&Fey::Exceptions::param_error );
EOF

        die $@ if $@;
    }

    $class->export_to_level( 1, undef, grep { $MyExports{$_} } @_ );
}


1;

__END__
