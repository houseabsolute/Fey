package Q::Test::Loader;

use strict;
use warnings;

use Test::More;
use Data::Dumper ();

use Q::Query::Quoter;


sub compare_schemas
{
    my $class    = shift;
    my $schema1  = shift;
    my $schema2  = shift;
    my $override = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    is( $schema1->name(), $schema2->name(),
        'schemas have the same name' );

    for my $table1 ( grep { $_->name() ne 'TestView' } $schema1->tables() )
    {
        my $name = $table1->name();
        my $table2 = $schema2->table($name);

        ok( $table2,
            "$name table found by loader exists in test schema" );

        my $expect =
            exists $override->{ $table1->name() }{is_view}
            ? $override->{ $table1->name() }{is_view}
            : $table2->is_view();
        is( $table1->is_view(), $expect,
            "schemas agree on is_view() for $name table" );

        $class->compare_pk( $table1, $table2, $override );
        $class->compare_columns( $table1, $table2, $override );
        $class->compare_fks( $table1, $table2, $override );
    }

    my $test_view_t = $schema1->table('TestView');
    ok( $test_view_t, 'TestView table exists in loader-made schema' );
    ok( $test_view_t->is_view(), 'TestView table is_view() is true' );

    for my $table2 ( $schema2->tables() )
    {
        my $name = $table2->name();

        ok( $schema1->table($name),
            "$name table in test schema was found by loader" );
    }
}

sub compare_pk
{
    my $class    = shift;
    my $table1   = shift;
    my $table2   = shift;
    my $override = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @pk1 = map { $_->name() } $table1->primary_key();
    my @pk2 = map { $_->name() } $table2->primary_key();

    my $expect =
        exists $override->{ $table1->name() }{primary_key}
        ? $override->{ $table1->name() }{primary_key}
        : \@pk2;

    is_deeply( \@pk1, $expect,
               "schemas agree on primary key for " . $table1->name() );
}

sub compare_columns
{
    my $class    = shift;
    my $table1   = shift;
    my $table2   = shift;
    my $override = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $quoter = Q::Query::Quoter->new( dbh => $table1->schema()->dbh() );

    for my $col1 ( $table1->columns() )
    {
        my $name = $col1->name();
        my $fq_name = join '.', $table1->name(), $name;

        my $col2 = $table2->column($name);
        ok( $col2,
            "$fq_name column found by loader exists in test schema" );

        for my $meth ( qw( type generic_type length precision
                           is_nullable is_auto_increment ) )
        {
            my $expect =
                exists $override->{$fq_name}{$meth}
                ? $override->{$fq_name}{$meth}
                : $col2->$meth();
            is( $col1->$meth(), $expect,
                "schemas agree on $meth for $fq_name" );
        }

        my $def1 = $col1->default();
        my $def2 =
            exists $override->{$fq_name}{default}
            ? $override->{$fq_name}{default}
            : $col2->default();

        $def1 = $def1->sql($quoter)
            if $def1;
        $def2 = $def2->sql($quoter)
            if $def2;

        is( $def1, $def2, "schemas agree on default for $fq_name" );
    }

    for my $col2 ( $table2->columns() )
    {
        my $name = $col2->name();

        ok( $table1->column($name),
            "$name column in test schema was found by loader" );
    }
}

sub compare_fks
{
    my $class    = shift;
    my $table1   = shift;
    my $table2   = shift;
    my $override = shift;

    return if $override->{skip_foreign_keys};

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $schema1 = $table1->schema();
    my $schema2 = $table2->schema();

    my %fk1 = map { $class->_fk_id($_) => 1 } $schema1->foreign_keys_for_table($table1);
    my %fk2 = map { $class->_fk_id($_) => 1 } $schema2->foreign_keys_for_table($table2);

    my $name = $table1->name();

    for my $id ( keys %fk1 )
    {
        ok( $fk2{$id},
            "fk for $name from loader is present in test schema" )
            or diag($id);
    }

    for my $id ( keys %fk2 )
    {
        ok( $fk1{$id},
            "fk for $name in test schema is present in loader" )
            or diag($id);
    }
}

sub _fk_id
{
    my $class = shift;
    my $fk    = shift;

    my %id = ( source_table   => $fk->source_table()->name(),
               source_columns => [ map { $_->name() } $fk->source_columns() ],
               target_table   => $fk->target_table()->name(),
               target_columns => [ map { $_->name() } $fk->target_columns() ],
             );

    my $dump = Data::Dumper::Dumper(\%id);
    $dump =~ s/^\$VAR1 = //;

    return $dump;
}


1;
