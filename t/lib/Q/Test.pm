package Q::Test;

use strict;
use warnings;

use DBI;
use File::Temp ();

use Q::Column;
use Q::FK;
use Q::Query::Quoter;
use Q::Schema;
use Q::Table;


BEGIN
{
    # This freaking module is reporting warnings from overload.pm,
    # which is calling can() as a method. Test::MockObject insists on
    # loading it for some reason.
    $INC{'UNIVERSAL/can.pm'} = 1;
}

use Test::MockObject;


sub mock_test_schema
{
    my $class    = shift;
    my $skip_dbh = shift;

    my $schema = Q::Schema->new( name => 'Test' );

    $schema->add_table( _user_table() );

    $schema->add_table( _group_table() );

    $schema->add_table( _user_group_table() );

    $schema->add_table( _message_table() );

    $schema->set_dbh( mock_dbh() )
        unless $skip_dbh;

    return $schema;
}

sub mock_test_schema_with_fks
{
    my $class  = shift;
    my $schema = $class->mock_test_schema(@_);

    my $fk =
        Q::FK->new
            ( source => [ $schema->table('User')->column('user_id') ],
              target => [ $schema->table('UserGroup')->column('user_id') ],
            );
    $schema->add_foreign_key($fk);

    return $schema;
}

sub _user_table
{
    my $t = Q::Table->new( name => 'User' );

    my $user_id =
        Q::Column->new( name              => 'user_id',
                        type              => 'integer',
                        is_auto_increment => 1,
                      );

    my $username =
        Q::Column->new( name => 'username',
                        type => 'text',
                      );

    my $email =
        Q::Column->new( name        => 'email',
                        type        => 'text',
                        is_nullable => 1,
                      );

    $t->add_column($_) for $user_id, $username, $email;
    $t->set_primary_key($user_id);

    return $t;
}

sub _group_table
{
    my $t = Q::Table->new( name => 'Group' );

    my $group_id =
        Q::Column->new( name              => 'group_id',
                        type              => 'integer',
                        is_auto_increment => 1,
                      );

    my $name =
        Q::Column->new( name => 'name',
                        type => 'text',
                      );

    $t->add_column($_) for $group_id, $name;
    $t->set_primary_key($group_id);

    return $t;
}

sub _user_group_table
{
    my $t = Q::Table->new( name => 'UserGroup' );

    my $user_id =
        Q::Column->new( name => 'user_id',
                        type => 'integer',
                      );

    my $group_id =
        Q::Column->new( name => 'group_id',
                        type => 'integer',
                      );

    $t->add_column($_) for $user_id, $group_id;
    $t->set_primary_key( $user_id, $group_id );

    return $t;
}

sub _message_table
{
    my $t = Q::Table->new( name => 'Message' );

    my $message_id =
        Q::Column->new( name              => 'message_id',
                        type              => 'integer',
                        is_auto_increment => 1,
                      );

    my $message =
        Q::Column->new( name    => 'message',
                        type    => 'text',
                        default => 'Some message text',
                      );

    my $quality =
        Q::Column->new( name      => 'quality',
                        type      => 'float',
                        length    => 5,
                        precision => 2,
                        default   => 2.3,
                      );

    $t->add_column($_) for $message_id, $message, $quality;
    $t->set_primary_key($message_id);

    return $t;
}

sub mock_dbh
{
    my $mock = Test::MockObject->new();

    $mock->set_isa('DBI::db');

    $mock->mock( 'get_info', \&_mock_get_info );

    $mock->mock( 'quote', \&_mock_quote );

    $mock->mock( 'table_info', \&_mock_table_info );

    $mock->mock( 'column_info', \&_mock_column_info );

    $mock->mock( 'primary_key', \&_mock_primary_key );

    $mock->mock( 'foreign_key_info', \&_mock_foreign_key_info );

    $mock->{Driver}{Name} = 'Mock';

    $mock->{__schema__} = __PACKAGE__->mock_test_schema_with_fks(1);

    $mock->{Name} = $mock->{__schema__}->name();

    return $mock;
}

{
    my %Info = ( 29 => q{"},
                 41 => q{.},
               );
    sub _mock_get_info
    {
        my $self = shift;
        my $num  = shift;

        return $Info{$num}
    }
}

sub _mock_quote
{
    my $self = shift;
    my $str  = shift;

    my $q = q{'};

    $str =~ s/$q/$q$q/g;

    return "$q$str$q";
}

sub _mock_table_info
{
    my $self = shift;

    unless ( $self->{__schema__}->table('TestView') )
    {
        my $table = Q::Table->new( name    => 'TestView',
                                   is_view => 1,
                                 );

        my $col = Q::Column->new( name         => 'user_id',
                                  type         => 'INTEGER',
                                  generic_type => 'integer',
                                );

        $table->add_column($col);
        $table->set_primary_key($col);

        $self->{__schema__}->add_table($table);
    }

    my @tables;
    for my $table ( $self->{__schema__}->tables() )
    {
        push @tables,
            { TABLE_NAME => $table->name(),
              TABLE_TYPE => ( $table->is_view() ? 'VIEW' : 'TABLE'),
            };
    }

    return Q::Test::MockSTH->new(\@tables);
}

sub _mock_column_info
{
    my $self       = shift;
    my $table_name = $_[2];

    my $table = $self->{__schema__}->table($table_name);

    return Q::Mock::STH->new() unless $table;

    my $quoter = Q::Query::Quoter->new( dbh => $self );

    my @columns;
    for my $col ( $table->columns() )
    {
        my %col =
            ( COLUMN_NAME   => $col->name(),
              DATA_TYPE     => $col->type(),
              SQL_DATA_TYPE => $col->generic_type(),
              NULLABLE      => $col->is_nullable(),
            );

        $col{COLUMN_SIZE} = $col->length()
            if defined $col->length();

        $col{DECIMAL_DIGITS} = $col->precision()
            if defined $col->precision();

        $col{COLUMN_DEF} = $col->default()->sql($quoter)
            if $col->default();

        push @columns, \%col;
    }

    return Q::Test::MockSTH->new(\@columns);
}

sub _mock_primary_key
{
    my $self       = shift;
    my $table_name = $_[2];

    my $table = $self->{__schema__}->table($table_name);

    return unless $table;

    return map { $_->name() } $table->primary_key();
}

sub _mock_foreign_key_info
{
    my $self       = shift;
    my $table_name = $_[2];

    my $table = $self->{__schema__}->table($table_name);

    return unless $table;

    my $x = 1;
    my @fk;
    my %pk = map { $_->name() => 1 } $table->primary_key();

    for my $fk ( $self->{__schema__}->foreign_keys_for_table($table) )
    {
        my @source = $fk->source_columns();

        next unless @source == keys %pk;
        next if grep { ! $pk{ $_->name() } } @source;

        my @target = $fk->target_columns();

        for ( my $x = 0; $x < @source; $x++ )
        {
            push @fk,
               { KEY_SEQ       => $x + 1,
                 PKTABLE_NAME  => $source[$x]->table()->name(),
                 PKCOLUMN_NAME => $source[$x]->name(),
                 FKTABLE_NAME  => $target[$x]->table()->name(),
                 FKCOLUMN_NAME => $target[$x]->name(),
               };
        }
    }

    return Q::Test::MockSTH->new(\@fk);
}


package Q::Test::MockSTH;

sub new
{
    my $class = shift;
    my $rows  = shift;

    return bless $rows, $class;
}

sub fetchrow_hashref
{
    my $self = shift;

    return unless @{$self};

    return shift @{$self};
}


1;
