use strict;
use warnings;

use Module::Build;

my $builder =
    Module::Build->new
        ( module_name        => 'Fey',
          license            => 'perl',
          requires =>
          { 'Exception::Class'                       => 0,
            'Exporter'                               => 0,
            'List::MoreUtils'                        => 0,
            'Moose'                                  => 0.45,
            'Moose::Policy'                          => 0.03,
            'MooseX::Policy::SemiAffordanceAccessor' => 0.02,
            'MooseX::StrictConstructor'              => 0,
            'Params::Validate'                       => 0.82,
            'Scalar::Util'                           => 0,
            'Task::Weaken'                           => 0.99,
          },
          build_requires =>
          { 'DBI'                   => 0,
            'Fey::Test'             => 0.05,
            'File::Temp'            => 0,
            'Test::MockObject'      => 0,
            'Test::More'            => 0,
          },
          recommends =>
          { 'Test::Memory::Cycle'   => 0,
          },
          create_makefile_pl   => 'passthrough',
          create_readme        => 1,
          sign                 => 1,
          recursive_test_files => 1,
        );

$builder->create_build_script();
