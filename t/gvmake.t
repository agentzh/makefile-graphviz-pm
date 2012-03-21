use strict;
use warnings;

use Test::More tests => 4;
use File::Compare;
#use Test::LongString;

my $out = `$^X -Ilib script/gvmake --help`;
is $out, <<'_EOC_';
Usage:
    gvmake [options] [target]*

Options:
    --all
    -a                Plot all the goals.
    -f <filename>
    -file <filename>  Use filename as Makefile.
    --help
    -h                Print this help.
    --size
    -s <w>x<h>        Specify the size (both for width and height)
    --out
    -o <filename>     Use filename as output PNG file.
    --edge-len <len>  Specify the "len" attribute for edges.
    --debug           Generate .dot file rather than PNG

_EOC_

is system("$^X -Ilib script/gvmake -f t/Makefile6 --edge-len 2 -o t/Makefile6.dot"), 0;
is fcmp('t/Makefile6.dot', 't/~Makefile6.dot'), 0;
unlink "t/Makefile6.dot";

is system("$^X -Ilib script/gvmake -f t/Makefile6"), 0;
unlink "blog.agentzh.org.png";
unlink "test.png";

sub fcmp {
    return File::Compare::compare_text(
        @_,
        sub {
            my ($a, $b) = @_;
            $a =~ s/[\r\n\s]//g;
            $b =~ s/[\r\n\s]//g;
            $a ne $b;
        }
    );
}

