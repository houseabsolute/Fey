use strict;
use warnings;

use Module::Build;

my $builder =
    Module::Build->new
        ( module_name        => 'Fey',
          license            => 'perl',
          requires =>
              { 'Exception::Class'               => '0',
                'Exporter'                       => '0',
                'List::AllUtils'                 => '0',
                'Moose'                          => '0.90',
                'MooseX::SemiAffordanceAccessor' => '0.03',
                'MooseX::StrictConstructor'      => '0.07',
                'MooseX::Params::Validate'       => '0.08',
                'MooseX::Role::Parameterized'    => '0.04',
                'Scalar::Util'                   => '0',
                'Task::Weaken'                   => '0.99',
              },
          build_requires =>
              { 'DBI'              => '0',
                'Fey::Test'        => '0.05',
                'File::Temp'       => '0',
                'Test::MockObject' => '0',
                'Test::More'       => '0',
              },
          recommends =>
              { 'Test::Memory::Cycle'   => '0',
              },
          create_makefile_pl   => 'traditional',
          create_readme        => 1,
          sign                 => 1,
          recursive_test_files => 1,
          meta_merge =>
              { resources =>
                    { homepage   => 'http://www.fey-project.org/',
                      bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Fey',
                      repository => 'http://hg.urth.org/hg/Fey',
                    },
              },
        );

$builder->create_build_script();
