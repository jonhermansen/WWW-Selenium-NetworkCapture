use Module::Build;

my $build = Module::Build->new(
    module_name  => 'WWW::Selenium::NetworkCapture',
    license      => 'GPL',
    dist_version => '0.01',
    requires     => {
	'WWW::Selenium' => '1.23'
    },
);

$build->dispatch('build');
$build->dispatch('test', verbose => 1);
$build->create_build_script;
