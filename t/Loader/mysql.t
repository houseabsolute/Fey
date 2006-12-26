use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Q::Test::Loader;
use Q::Test::mysql;

use Test::More tests => 120;

use Q::Literal;
use Q::Loader;


{
    my $loader = Q::Loader->new( dbh => Q::Test::SQLite->dbh() );

    my $schema1 = $loader->make_schema( name => 'Test' );
    my $schema2 = Q::Test->mock_test_schema_with_fks();

    Q::Test::Loader->compare_schemas
        ( $schema1, $schema2,
          { 'Message.message_id' =>
                { type   => 'INT',
                  length => 11,
                },
            'Message.message' =>
                { type   => 'VARCHAR',
                  length => 255,
                },
            'Message.quality' =>
                { type    => 'DECIMAL',
                  default => Q::Literal->term('2.30'),
                },
            'Message.message_date' =>
                { type         => 'TIMESTAMP',
                  length       => 14,
                  precision    => 0, # gah, mysql is so weird
                  generic_type => 'datetime',
                  default      => Q::Literal->term('CURRENT_TIMESTAMP'),
                  # mysql seems to always consider timestamp columns nullable
                  is_nullable  => 1,
                },
            'User.user_id' =>
                { type   => 'INT',
                  length => 11,
                },
            'User.username' =>
                { type    => 'TEXT',
                  default => Q::Literal->string(''),
                },
            'User.email' =>
                { type   => 'TEXT',
                },
            'UserGroup.group_id' =>
                { type   => 'INT',
                  length => 11,
                },
            'UserGroup.user_id' =>
                { type   => 'INT',
                  length => 11,
                },
            'Group.group_id' =>
                { type   => 'INT',
                  length => 11,
                },
            'Group.name' =>
                { type    => 'TEXT',
                  default => Q::Literal->string(''),
                },
          },
        );
}
