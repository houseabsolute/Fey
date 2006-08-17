

{
    my $s = Q::Schema->new( name => 'Test' );

    is( $s->name(), 'Test', 'schema name is Test' );

    $s->set_dbh( Q::Test->mock_dbh );
    ok( $s->dbh(), 'set_dbh() sets the database handle' );
}
