use strict;
use inc::Module::Install;

my $gvmake = "script/gvmake";

name            ('Makefile-GraphViz');
version_from    ('lib/Makefile/GraphViz.pm');
abstract       ( 'Plot Makefile building process using GraphViz' );
author          ('Agent Zhang <agent2002@126.com>');
license         ('perl');

install_script  ($gvmake);

requires        ('GraphViz');
requires        ('Makefile::Parser' => '0.11');

build_requires  ('Test::More');
build_requires  ('File::Compare');

&WriteAll;
