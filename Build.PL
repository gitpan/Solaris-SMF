use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Solaris::SMF',
    license             => 'perl',
    dist_author         => q{Brad Macpherson <brad@teched-creations.com>},
    dist_version_from   => 'lib/Solaris/SMF.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Solaris-SMF-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
