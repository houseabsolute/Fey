use strict;
use warnings;

use Test::More;

BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for release candidate testing');
    }
}

use Test::Pod::Coverage 1.04;
use Pod::Coverage::Moose;

my @mods = sort grep { include($_) } Test::Pod::Coverage::all_modules();

plan tests => scalar @mods;

for my $mod (@mods) {
    my @trustme = qr/^BUILD(?:ARGS)?$/;

    pod_coverage_ok(
        $mod, {
            coverage_class => 'Pod::Coverage::Moose',
            trustme        => \@trustme,
        },
        "pod coverage for $mod"
    );
}

sub include {
    my $mod = shift;

    return 0 if $mod =~ /::Fragment::/;
    return 0 if $mod =~ /::Test/;
    return 0 if $mod =~ /::Validate/;
    return 0 if $mod =~ /::FakeDBI/;

    return 1;
}
