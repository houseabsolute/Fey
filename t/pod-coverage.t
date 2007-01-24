use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;

my @mods = sort grep { ! /::Fragment::|::Test/ } Test::Pod::Coverage::all_modules();

plan tests => scalar @mods;


my %TraitMethods;
for my $trait ( grep { /^Fey::Trait/ } @mods )
{
    my $pc = Pod::Coverage->new( package => $trait );
    @TraitMethods{ $pc->_get_syms($trait) } = ();
}

my $trait_meth_re =
    join '|', sort keys %TraitMethods;
$trait_meth_re = qr/^(?:$trait_meth_re)$/;

for my $mod (@mods)
{
    my $trustme = {};
    $trustme = { trustme => [ $trait_meth_re ] }
        unless $mod =~ /::Trait::/;

    pod_coverage_ok( $mod, $trustme, "pod coverage for $mod" );
}
