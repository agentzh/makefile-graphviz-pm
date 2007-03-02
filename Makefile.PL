use strict;
use inc::Module::Install;

my $gvmake = "script/gvmake";

name            ('Makefile-GraphViz');
all_from        ('lib/Makefile/GraphViz.pm');

install_script  ($gvmake);

requires        ('GraphViz' => '2.02');
requires        ('Makefile::Parser' => '0.11');

build_requires  ('Test::More');
build_requires  ('File::Compare' => '1.1003');

auto_install;
WriteAll;

