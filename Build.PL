use Module::Build;

my $build = Module::Build->new(
    module_name  => 'WWW::Selenium::NetworkCapture',
    license      => 'GPL',
    dist_version => '0.01',
    requires     => {
	DateTime => 0,
	URI::Split => 0,
	WWW::Selenium => 0,
	XML::Simple => 0,
    },
);

$build->dispatch('build');
$build->dispatch('test', verbose => 1);
#$build->dispatch('install');
$build->create_build_script;
