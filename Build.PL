use strict;
use warnings;

use Module::Build;

my $builder =
    Module::Build->new
        ( module_name        => 'Fey::Core',
          license            => 'perl',
          requires           =>
          { 'Class::Accessor::Fast' => 0,
            'Data::Dumper'          => 0,
            'DBI'                   => 0,
            'Exception::Class'      => 0,
            'Exporter'              => 0,
            'List::MoreUtils'       => 0,
            'Params::Validate'      => 0.82,
            'Scalar::Util'          => 0,
            'Task::Weaken'          => 0.99,
          },
          build_requires =>
          { 'Test::MockObject'      => 0,
            'Test::More'            => 0,
          },
          recommends =>
          { 'Test::Memory::Cycle'   => 0,
          },
          create_makefile_pl   => 'passthrough',
          create_readme        => 1,
          recursive_test_files => 1,
        );

$builder->create_build_script();
