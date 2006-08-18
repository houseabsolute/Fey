package Q::Validate;

use strict;
use warnings;

use base 'Exporter';

use Data::Dumper ();
use Params::Validate qw(:types);

use Q::Exceptions qw( param_error );


my %Types;
BEGIN {
    %Types =
        ( POS_INTEGER_TYPE =>
          { type => SCALAR,
            callbacks =>
            { 'is a positive integer' =>
              sub { $_[0] =~ qr/^\d+$/ && $_[0] > 0 }
            }
          },

          POS_OR_ZERO_INTEGER_TYPE =>
          { type => SCALAR,
            callbacks =>
            { 'is a positive or zero integer' =>
              sub { $_[0] =~ qr/^\d+$/ && $_[0] >= 0 }
            }
          },

          DBI_TYPE =>
          { type => OBJECT,
            isa  => 'DBI',
          },

          ( map { $_ . '_TYPE' => { type => eval $_ } }
            grep { /^[A-Z]+$/ } @Params::Validate::EXPORT_OK,
          )
        );

    for my $class ( qw( Schema Table Column FK ) )
    {
        $Types{ uc $class . '_TYPE' } = { isa => "Q::${class}" };
    }

    for my $class ( qw( Table Column ) )
    {
        $Types{ uc $class . '_OR_NAME_TYPE' } =
            { type      => SCALAR|OBJECT,
              callbacks =>
              { 'is an object or name' =>
                sub { defined $_[0]
                      && ( ! blessed $_[0] || $_[0]->isa($class) ) },
              },
            };
    }

    for my $t ( keys %Types )
    {
        my $base_data = Data::Dumper::Dumper( $Types{$t} );

        $base_data =~ s/.*\$VAR1 = {(.+)}.*/$1/s;
        eval <<"EOF";
sub $t {
    param_error "Invalid additional args for $t: [\@_]" if \@_ % 2;
    return { \@_, $base_data }
};
EOF
        die $@ if $@;
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
Params::Validate::set_options( on_fail => \\&Q::Exceptions::param_error );
EOF

        die $@ if $@;
    }

    $class->export_to_level( 1, undef, grep { $MyExports{$_} } @_ );
}


1;

__END__
