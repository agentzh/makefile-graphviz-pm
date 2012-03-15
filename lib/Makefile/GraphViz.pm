package Makefile::GraphViz;

use strict;
use warnings;
use vars qw($VERSION);

#use Smart::Comments;
use GraphViz;
use base 'Makefile::Parser';

$VERSION = '0.20';

$Makefile::Parser::Strict = 0;

our $IDCounter = 0;

my %VirNodeStyle =
(
    shape => 'plaintext',
);

my %NormalNodeStyle =
(
    shape => 'box',
    style => 'filled',
    fillcolor => '#f5f694',
);

my %EdgeStyle =
(
    color => 'red',
);

my %CmdStyle =
(
    shape => 'ellipse',
    style => 'filled',
    fillcolor => '#c7f77c',
);

my %InitArgs = (
    layout => 'dot',
    ratio => 'auto',
    node => \%NormalNodeStyle,
    edge => \%EdgeStyle,
);

our %Nodes;

sub _gen_id () {
    return ++$IDCounter;
}

sub _trim_path ($) {
    my $s = shift;
    $s =~ s/.+(.{5}[\\\/].*)$/...$1/o;
    $s =~ s/\\/\\\\/g;
    return $s;
}

sub _trim_cmd ($) {
    my $s = shift;
    $s =~ s/((?:\S+\s+){2})\S.*/$1.../o;
    $s =~ s/\\/\\\\/g;
    return $s;
}

sub _find ($@) {
    my $elem = shift;
    foreach (@_) {
        if (ref $_) {
            return 1 if $elem =~ $_;
        }

        return 1 if $elem eq $_;
    }
    return undef;
}

sub plot ($$@) {
    my $self = shift;
    my $root_name = shift;
    my %opts = @_;
    #warn "@_\n";

    # process the ``gv'' option:
    my $gv = $opts{gv};

    # process the ``vir_nodes'' option:
    my $val = $opts{vir_nodes};
    my @vir_nodes = @$val if $val and ref $val;
    my %vir_nodes;
    map { $vir_nodes{$_} = 1 } @vir_nodes;

    # process the ``normal_nodes'' option:
    $val = $opts{normal_nodes};
    my @normal_nodes = @$val if $val and ref $val;
    my %normal_nodes;
    map { $normal_nodes{$_} = 1 } @normal_nodes;

    # process the ``init_args'' option:
    $val = $opts{init_args};
    my %init_args = ($val and ref $val) ? %$val : %InitArgs;

    # process the ``edge_style'' option:
    $val = $opts{edge_style};
    my %edge_style = ($val and ref $val) ? %$val : %EdgeStyle;
    $init_args{edge} = \%edge_style;

    # process the ``normal_node_style'' option:
    $val = $opts{normal_node_style};
    my %normal_node_style = ($val and ref $val) ? %$val : %NormalNodeStyle;
    $init_args{node} = \%normal_node_style;

    # process the ``vir_node_style'' option:
    $val = $opts{vir_node_style};
    my %vir_node_style = ($val and ref $val) ? %$val : %VirNodeStyle;

    # process the ``cmd_style'' option:
    $val = $opts{cmd_style};
    my %cmd_style = ($val and ref $val) ? %$val : %CmdStyle;

    # process the ``trim_mode'' option:
    my $trim_mode = $opts{trim_mode};
    #warn "TRIM MODE: $trim_mode\n";

    # process the ``end_with'' option:
    $val = $opts{end_with};
    my @end_with = ($val and ref $val) ? @$val : ();

    # process the ``exclude'' option:
    $val = $opts{exclude};
    my @exclude = ($val and ref $val) ? @$val : ();

    return $gv if _find($root_name, @exclude);

    if (!$gv) {
        $gv = GraphViz->new(%init_args);
        %Nodes = ();
    }

    my $is_virtual = 0;
    if ($Nodes{$root_name}) {
        return $gv;
    }
    $Nodes{$root_name} = 1;
    #warn "GraphViz: $gv\n";

    my @roots = ($root_name and ref $root_name) ?
        $root_name : ($self->target($root_name));

    my $short_name = _trim_path($root_name);
    if ($normal_nodes{$root_name}) {
        $is_virtual = 0;
    } elsif ($vir_nodes{$root_name} or @roots and !$roots[0]->commands) {
        $is_virtual = 1;
    }

    if (!@roots or _find($root_name, @end_with)) {
        $gv->add_node(
            $root_name,
            label => $short_name,
            $is_virtual ? %vir_node_style : ()
        );
        return $gv;
    }
    #my $short_name = $root_name;

    my $i = 0;
    for my $root (@roots) {
        #warn $i, "???\n";
        ### $root_name
        ### $root
        #$short_name =~ s/\\/\//g;
        #warn $short_name, "\n";
        #warn $short_name, "!!!!!!!!!!!!!!!!\n";
        $gv->add_node(
            $root_name,
            label => $short_name,
            $is_virtual ? %vir_node_style : ()
        );

        #warn $gv;
        my $lower_node;
        my @cmds = $root->commands;
        if (!$trim_mode and @cmds) {
            $lower_node = _gen_id();
            my $cmds = join("\n", map { _trim_cmd($_); } @cmds);
            $gv->add_node($lower_node, label => $cmds, %cmd_style);
            $gv->add_edge(
                $lower_node => $root_name,
                $is_virtual ? (style => 'dashed') : ()
            );
        } else {
            $lower_node = $root_name;
        }

        my @prereqs = $root->prereqs;
        foreach (@prereqs) {
            #warn "$_\n";
            next if _find($_, @exclude);
            $gv->add_edge(
                $_ => $lower_node,
                $is_virtual ? (style => 'dashed') : ());
            #warn "$_ ++++++++++++++++++++\n";
            $self->plot($_, gv => $gv, @_);
        }
        #warn "END\n";
        #warn "GraphViz: $gv\n";
    } continue { $i++ }
    return $gv;
}

sub plot_all ($) {
    my $self = shift;
    my $gv = GraphViz->new(%InitArgs);
    %Nodes = ();
    for my $target ($self->roots) {
        $self->plot($target, gv => $gv);
    }
    $gv;
}

1;
__END__

=encoding utf-8

=head1 NAME

Makefile::GraphViz - Draw building flowcharts from Makefiles using GraphViz

=head1 VERSION

This document describes Makefile::GraphViz 0.20 released on 29 November 2011.

=head1 SYNOPSIS

  use Makefile::GraphViz;

  $parser = Makefile::GraphViz->new;
  $parser->parse('Makefile');

  # plot the tree rooted at the 'install' goal in Makefile:
  $gv = $parser->plot('install');  # A GraphViz object returned.
  $gv->as_png('install.png');

  # plot the tree rooted at the 'default' goal in Makefile:
  $gv = $parser->plot;
  $gv->as_png('default.png');

  # plot the forest consists of all the goals in Makefile:
  $gv = $parser->plot_all;
  $gv->as_png('default.png');

  # you can also invoke all the methods
  # inherited from the Makefile::Parser class:
  @targets = $parser->targets;

=head1 DESCRIPTION

This module uses L<Makefile::Parser> to render user's Makefiles via the amazing
L<GraphViz> module. Before I decided to write this thing, there had been already a
CPAN module named L<GraphViz::Makefile> which did the same thing. However, the
pictures generated by L<GraphViz::Makefile> is oversimplified in my opinion, so
a much complex one is still needed.

For everyday use, the L<gvmake> utility is much more convenient than using this
module directly. :)

B<WARNING> This module is highly experimental and is currently at
B<alpha> stage, so production use is strongly discouraged right now.
Anyway, I have the plan to improve this stuff unfailingly.

For instance, the following makefile

    all: foo
    all: bar
            echo hallo

    any: foo hiya
            echo larry
            echo howdy
    any: blah blow

    foo:: blah boo
            echo Hi
    foo:: howdy buz
            echo Hey

produces the following image via the C<plot_all> method:

=begin html

<!-- this h1 part is for search.cpan.org -->
<h1>
<a class = 'u' 
   href  = '#___top'
   title ='click to go to top of document'
   name  = "PNG IMAGE"
>PNG IMAGE</a>
</h1>

<p><img src="http://agentzh.org/misc/multi.png" border=0 alt="image hosted by agentzh.org"/></p>
<p>Image hosted by <a href="http://agentzh.org">agentzh.org</a></p>

=end html

=head1 SAMPLE PICTURES

Browse L<http://search.cpan.org/src/AGENT/Makefile-GraphViz-0.16/samples.html>
for some sample output graphs.

=head1 INSTALLATION

Prerequisites L<GraphViz> and L<Makefile::Parser> should be installed to your
Perl distribution first. Among other things, the L<GraphViz> module needs tools
"dot", "neato", "twopi", "circo" and "fdp" from the Graphviz project
(L<http://www.graphviz.org/> or L<http://www.research.att.com/sw/tools/graphviz/>).
Hence you have to download an executable package of AT&T's Graphviz for your platform
or build it from source code yourself.

=head1 The Makefile::GraphViz Class

This class is a subclass inherited from L<Makefile::Parser>. So all the methods (and
hence all the functionalities) provided by L<Makefile::Parser> are accessible here.
Additionally this class also provides some more methods on its own right.

=head1 METHODS

=over

=item C<< $graphviz = plot($target, ...) >>

This method is essential to the class. Users invoke this method to plot the specified
Makefile target. If the argument is absent, the default target in the Makefile will
be used. It will return a L<GraphViz> object, on which you can later call the
C<as_png> or C<as_text> method to obtain the final graphical output.

The argument can both be the target's name and a Makefile::Target object. If the
given target can't be found in Makefile, the target will be plotted separately.

This method also accepts several options.

    $gv = $parser->plot(undef, normal_nodes => ['mytar']);
    $gv = $parser->plot(
        'cmintester',
        exclude  => [qw(
            all hex2bin.exe exe2hex.pl bin2asm.pl
            asm2ast.pl ast2hex.pl cod2ast.pl
        )],
        end_with => [qw(pat_cover.ast pat_cover)],
        normal_nodes => ['pat_cover.ast'],
        vir_nodes => ['pat_cover'],
        trim_mode => 0,
    );

=over

=item cmd_style

This option controls the style of the shell command box. The default
appearance for these nodes are gray ellipses.

=item edge_style

This option's value will be passed directly to GraphViz's add_edge
method. It controls the appearance of the edges in the output graph,
which is default to red directed arrows.

    $gv = $parser->plot(
        'install',
        edge_style => {
            style => 'dotted',
            color => 'seagreen',
        },
    );

=item end_with

This option takes a list ref as its value. The plot method
won't continue to iterate the subtree rooted at entries in the
list. It is worth noting that the entries themselves will be
displayed as usual. This is the only difference compared to
the B<exclude> option.

Here is an example:

    $gv = $parser->plot(
        'cmintester',
        end_with => [qw(pat_cover.ast pat_cover)],
    );

=item exclude

This option takes a list ref as its value. All the entries
in the list won't be displayed and the subtrees rooted at 
these entries won't be displayed either.

    $parser->plot(
        'clean',
        exclude=>[qw(foo.exe foo.pl)]
    )->as_png('clean.png');

=item gv

This option accepts user's GraphViz object to render the graph.

    $gv = GraphViz->new(width => 30, height => 20,
                        pagewidth => 8.5, pageheight => 11);
    $parser->plot('install', gv => $gv);
    print $gv->as_text;

=item init_args

This option takes a hash ref whose value will be passed to the
constructor of the GraphViz class if the option B<gv> is not
specified:

    $parser->plot(
        'install',
        init_args => {
            width => 30, height => 20,
            pagewidth => 8.5, pageheight => 11,
        },
    )->as_png('a.png');

=item normal_nodes

The entries in this option's list are forced to be the
normal nodes. Normal nodes are defined to be the Makefile
targets corresponding to disk files. In contrast, virtual
nodes are those Makefile targets with no real files
corresponding to them.

=item normal_node_style

Override the default style for the normal nodes. By default,
normal nodes are yellow rectangles with black border.

    $gv = $parser->plot(
        'install',
        normal_node_style => {
           shape => 'circle',
           style => 'filled',
           fillcolor => 'red',
        },
    );

=item trim_mode

When this option is set to a true value, no shell command
nodes will be plotted.

=item vir_nodes

The entries in this option's list are forced to be the
virtual nodes. Virtual nodes are those Makefile targets
with no real files corresponding to them, which are generally
called "phony targets" in the GNU make Manual and "pseudo targets"
in MS NMAKE's docs.

=item vir_node_style

Override the default style for the virtual nodes.

    $gv = $parser->plot(
        'install',
        virtual_node_style => {
           shape => 'box',
           style => 'filled',
           fillcolor => 'blue',
        },
    );

By default, virtual nodes are yellow rectangles with no
border.

=back

=item C<< $graphviz = $object->plot_all() >>

Plot all the (root) goals appeared in the Makefile.

=back

=head2 INTERNAL FUNCTIONS

Internal functions should not be used directly.

=over

=item _gen_id

Generate a unique id for command node.

=item _trim_path

Trim the path to a more readable form.

=item _trim_cmd

Trim the shell command to a more friendly size.

=item _find

If the given element is found in the given list, this
function will return 1; otherwise, a false value is
returned.

=back

=head1 TODO

=over

=item *

Add support for the various options provided by the
C<plot> method to the C<plot_all> method.

=item *

Use L<Params::Util> to check the validity of the
method arguments.

=item *

Use the next generation of L<Makefile::Parser> to do
the underlying parsing job.

=back

=head1 CODE COVERAGE

I use L<Devel::Cover> to test the code coverage of my tests,
below is the L<Devel::Cover> report on this module test suite.

  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  File                           stmt   bran   cond    sub    pod   time  total
  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  .../lib/Makefile/GraphViz.pm  100.0   93.2   71.4  100.0  100.0   61.5   92.1
  ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SOURCE CONTROL

For the very latest version of this module, check out the source from
the Git repository below:

L<https://github.com/agentzh/makefile-graphviz-pm>

There is anonymous access to all. If you'd like a commit bit, please let
me know. :)

=head1 BUGS

Please report bugs or send wish-list to
L<https://github.com/agentzh/makefile-graphviz-pm/issues>.

=head1 SEE ALSO

L<gvmake>, L<GraphViz>, L<Makefile::Parser>.

=head1 AUTHOR

Zhang "agentzh" Yichun (章亦春) C<< <agentzh@gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2011 by Zhang "agentzh" Yichun (章亦春).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

