use strict;
use inc::Module::Install;

my $gvmake = "script/gvmake";

name            ('Makefile-GraphViz');
all_from        ('lib/Makefile/GraphViz.pm');

#my $version = version();
#$version =~ s{(\d{3})(\d{3})?$}{int($1).'.'.int($2||0)}e;
#version($version);

install_script  ($gvmake);

requires        ('GraphViz' => '2.02');
requires        ('Makefile::Parser' => '0.13');

build_requires  ('Test::More' => '0.62');
build_requires  ('File::Compare' => '1.1003');

no_index        (
    directory =>
        qw< samples >
);

auto_install;
WriteAll;

