use strict;
use warnings;

use Test::More;

plan skip_all => 'This test is only run for the module author'
    unless -d '.svn' || $ENV{IS_MAINTAINER};

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage'
    if $@;

my @mods = sort grep { ! /::Fragment::|::Test|::Validate/ } Test::Pod::Coverage::all_modules();

plan tests => scalar @mods;


my %RoleMethods;
for my $role ( grep { /^Fey::Role/ } @mods )
{
    my $pc = Pod::Coverage->new( package => $role );
    @RoleMethods{ $pc->_get_syms($role) } = ();
}

my $role_meth_re =
    join '|', map { quotemeta } sort keys %RoleMethods;
$role_meth_re = qr/^(?:$role_meth_re)$/;

for my $mod (@mods)
{
    my @trustme = qr/^(?:meta|BUILD)$/;
    push @trustme, $role_meth_re,
        unless $mod =~ /::Role::/;

    pod_coverage_ok( $mod, { trustme => \@trustme },
                     "pod coverage for $mod" );
}
