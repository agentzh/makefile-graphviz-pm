# NAME

Makefile::GraphViz - Draw building flowcharts from Makefiles using GraphViz

Table of Contents
=================

* [NAME](#name)
* [VERSION](#version)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [SAMPLE PICTURES](#sample-pictures)
* [INSTALLATION](#installation)
* [The Makefile::GraphViz Class](#the-makefilegraphviz-class)
* [METHODS](#methods)
    * [INTERNAL FUNCTIONS](#internal-functions)
* [TODO](#todo)
* [CODE COVERAGE](#code-coverage)
* [SOURCE CONTROL](#source-control)
* [BUGS](#bugs)
* [SEE ALSO](#see-also)
* [AUTHOR](#author)
* [COPYRIGHT AND LICENSE](#copyright-and-license)

# VERSION

This document describes Makefile::GraphViz 0.20 released on 29 November 2011.

# SYNOPSIS

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

# DESCRIPTION

This module uses [Makefile::Parser](https://metacpan.org/pod/Makefile::Parser) to render user's Makefiles via the amazing
[GraphViz](https://metacpan.org/pod/GraphViz) module. Before I decided to write this thing, there had been already a
CPAN module named [GraphViz::Makefile](https://metacpan.org/pod/GraphViz::Makefile) which did the same thing. However, the
pictures generated by [GraphViz::Makefile](https://metacpan.org/pod/GraphViz::Makefile) is oversimplified in my opinion, so
a much complex one is still needed.

For everyday use, the [gvmake](https://metacpan.org/pod/gvmake) utility is much more convenient than using this
module directly. :)

**WARNING** This module is highly experimental and is currently at
**alpha** stage, so production use is strongly discouraged right now.
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

produces the following image via the `plot_all` method:

<div>
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
</div>

[Back to TOC](#table-of-contents)

# SAMPLE PICTURES

Browse [http://search.cpan.org/src/AGENT/Makefile-GraphViz-0.16/samples.html](http://search.cpan.org/src/AGENT/Makefile-GraphViz-0.16/samples.html)
for some sample output graphs.

[Back to TOC](#table-of-contents)

# INSTALLATION

Prerequisites [GraphViz](https://metacpan.org/pod/GraphViz) and [Makefile::Parser](https://metacpan.org/pod/Makefile::Parser) should be installed to your
Perl distribution first. Among other things, the [GraphViz](https://metacpan.org/pod/GraphViz) module needs tools
"dot", "neato", "twopi", "circo" and "fdp" from the Graphviz project
([http://www.graphviz.org/](http://www.graphviz.org/) or [http://www.research.att.com/sw/tools/graphviz/](http://www.research.att.com/sw/tools/graphviz/)).
Hence you have to download an executable package of AT&T's Graphviz for your platform
or build it from source code yourself.

[Back to TOC](#table-of-contents)

# The Makefile::GraphViz Class

This class is a subclass inherited from [Makefile::Parser](https://metacpan.org/pod/Makefile::Parser). So all the methods (and
hence all the functionalities) provided by [Makefile::Parser](https://metacpan.org/pod/Makefile::Parser) are accessible here.
Additionally this class also provides some more methods on its own right.

[Back to TOC](#table-of-contents)

# METHODS

- `$graphviz = plot($target, ...)`

    This method is essential to the class. Users invoke this method to plot the specified
    Makefile target. If the argument is absent, the default target in the Makefile will
    be used. It will return a [GraphViz](https://metacpan.org/pod/GraphViz) object, on which you can later call the
    `as_png` or `as_text` method to obtain the final graphical output.

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

    - cmd\_style

        This option controls the style of the shell command box. The default
        appearance for these nodes are gray ellipses.

    - edge\_style

        This option's value will be passed directly to GraphViz's add\_edge
        method. It controls the appearance of the edges in the output graph,
        which is default to red directed arrows.

            $gv = $parser->plot(
                'install',
                edge_style => {
                    style => 'dotted',
                    color => 'seagreen',
                },
            );

    - end\_with

        This option takes a list ref as its value. The plot method
        won't continue to iterate the subtree rooted at entries in the
        list. It is worth noting that the entries themselves will be
        displayed as usual. This is the only difference compared to
        the **exclude** option.

        Here is an example:

            $gv = $parser->plot(
                'cmintester',
                end_with => [qw(pat_cover.ast pat_cover)],
            );

    - exclude

        This option takes a list ref as its value. All the entries
        in the list won't be displayed and the subtrees rooted at 
        these entries won't be displayed either.

            $parser->plot(
                'clean',
                exclude=>[qw(foo.exe foo.pl)]
            )->as_png('clean.png');

    - gv

        This option accepts user's GraphViz object to render the graph.

            $gv = GraphViz->new(width => 30, height => 20,
                                pagewidth => 8.5, pageheight => 11);
            $parser->plot('install', gv => $gv);
            print $gv->as_text;

    - init\_args

        This option takes a hash ref whose value will be passed to the
        constructor of the GraphViz class if the option **gv** is not
        specified:

            $parser->plot(
                'install',
                init_args => {
                    width => 30, height => 20,
                    pagewidth => 8.5, pageheight => 11,
                },
            )->as_png('a.png');

    - normal\_nodes

        The entries in this option's list are forced to be the
        normal nodes. Normal nodes are defined to be the Makefile
        targets corresponding to disk files. In contrast, virtual
        nodes are those Makefile targets with no real files
        corresponding to them.

    - normal\_node\_style

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

    - trim\_mode

        When this option is set to a true value, no shell command
        nodes will be plotted.

    - vir\_nodes

        The entries in this option's list are forced to be the
        virtual nodes. Virtual nodes are those Makefile targets
        with no real files corresponding to them, which are generally
        called "phony targets" in the GNU make Manual and "pseudo targets"
        in MS NMAKE's docs.

    - vir\_node\_style

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

- `$graphviz = $object->plot_all()`

    Plot all the (root) goals appeared in the Makefile.

[Back to TOC](#table-of-contents)

## INTERNAL FUNCTIONS

Internal functions should not be used directly.

- \_gen\_id

    Generate a unique id for command node.

- \_trim\_path

    Trim the path to a more readable form.

- \_trim\_cmd

    Trim the shell command to a more friendly size.

- \_find

    If the given element is found in the given list, this
    function will return 1; otherwise, a false value is
    returned.

[Back to TOC](#table-of-contents)

# TODO

- Add support for the various options provided by the
`plot` method to the `plot_all` method.
- Use [Params::Util](https://metacpan.org/pod/Params::Util) to check the validity of the
method arguments.
- Use the next generation of [Makefile::Parser](https://metacpan.org/pod/Makefile::Parser) to do
the underlying parsing job.

[Back to TOC](#table-of-contents)

# CODE COVERAGE

I use [Devel::Cover](https://metacpan.org/pod/Devel::Cover) to test the code coverage of my tests,
below is the [Devel::Cover](https://metacpan.org/pod/Devel::Cover) report on this module test suite.

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    .../lib/Makefile/GraphViz.pm  100.0   93.2   71.4  100.0  100.0   61.5   92.1
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

[Back to TOC](#table-of-contents)

# SOURCE CONTROL

For the very latest version of this module, check out the source from
the Git repository below:

[https://github.com/agentzh/makefile-graphviz-pm](https://github.com/agentzh/makefile-graphviz-pm)

There is anonymous access to all. If you'd like a commit bit, please let
me know. :)

[Back to TOC](#table-of-contents)

# BUGS

Please report bugs or send wish-list to
[https://github.com/agentzh/makefile-graphviz-pm/issues](https://github.com/agentzh/makefile-graphviz-pm/issues).

[Back to TOC](#table-of-contents)

# SEE ALSO

[gvmake](https://metacpan.org/pod/gvmake), [GraphViz](https://metacpan.org/pod/GraphViz), [Makefile::Parser](https://metacpan.org/pod/Makefile::Parser).

[Back to TOC](#table-of-contents)

# AUTHOR

Zhang "agentzh" Yichun (章亦春) `<agentzh@gmail.com>`

[Back to TOC](#table-of-contents)

# COPYRIGHT AND LICENSE

Copyright (c) 2005-2011 by Zhang "agentzh" Yichun (章亦春).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

[Back to TOC](#table-of-contents)

