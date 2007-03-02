#: Makefile/GraphViz.pm
#: Plot the detailed structure of Makefiles
#:   using GraphViz
#: v0.11
#: Copyright (c) 2005 Agent Zhang
#: 2005-09-30 2005-11-04

package Makefile::GraphViz;

use strict;
use warnings;

use GraphViz;
use base 'Makefile::Parser';

$Makefile::Parser::Strict = 0;

our $VERSION = '0.11';

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

sub plot {
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

    my $root = ($root_name and ref $root_name) ?
        $root_name : ($self->target($root_name));

    if (!$gv) {
        $gv = GraphViz->new(%init_args);
        %Nodes = ();
    }

    return $gv if find($root_name, @exclude);
    #warn $gv;
    my $is_virtual = 0;
    if (!$Nodes{$root_name}) {
        my $short_name = trim_path($root_name);
        #$short_name =~ s/\\/\//g;
        #warn $short_name, "\n";
        if ($normal_nodes{$root_name}) {
            $is_virtual = 0;
        } elsif ($vir_nodes{$root_name} or ($root and !$root->commands)) {
            $is_virtual = 1;
        }
        $gv->add_node(
            $root_name,
            label => $short_name,
            $is_virtual ? %vir_node_style : ()
        );
        $Nodes{$root_name} = 1;
    } else {
        return $gv;
    }
    #warn "GraphViz: $gv\n";
    return $gv if !$root or find($root_name, @end_with);

    my $lower_node;
    my @cmds = $root->commands;
    if (!$trim_mode and @cmds) {
        $lower_node = gen_id();
        my $cmds = join("\n", map { trim_cmd($_); } @cmds);
        $gv->add_node($lower_node, label => $cmds, %cmd_style);
        $gv->add_edge(
            $lower_node => $root_name,
            $is_virtual ? (style => 'dashed') : ()
        );
    } else {
        $lower_node = $root_name;
    }

    my @depends = $root->depends;
    foreach (@depends) {
        #warn "$_\n";
        next if find($_, @exclude);
        $gv->add_edge(
            $_ => $lower_node,
            $is_virtual ? (style => 'dashed') : ());
        $self->plot($_, gv => $gv, @_);
    }
    #warn "END\n";
    #warn "GraphViz: $gv\n";
    return $gv;
}

sub gen_id {
    return ++$IDCounter;
}

sub trim_path {
    my $s = shift;
    $s =~ s/.+(.{5}[\\\/].*)$/...$1/o;
    $s =~ s/\\/\\\\/g;
    return $s;
}

sub trim_cmd {
    my $s = shift;
    $s =~ s/((?:\S+\s+){2})\S.*/$1.../o;
    $s =~ s/\\/\\\\/g;
    return $s;
}

sub find {
    my $elem = shift;
    foreach (@_) {
        return 1 if $elem eq $_;
    }
    return undef;
}

1;
__END__

=head1 NAME

Makefile::GraphViz - Plot the Detailed Structure of Makefiles Using GraphViz                        

=head1 SYNOPSIS

  use Makefile::GraphViz;

  $parser = Makefile::GraphViz->new;
  $parser->parse('Makefile');

  # plot the tree rooted at the install target in Makefile:
  $gv = $parser->plot('install');  # A GraphViz object returned.
  $gv->as_png('install.png');

  # plot the tree rooted at the default target in Makefile:
  $gv = $parser->plot;
  $gv->as_png('default.png');

  # plot the forest consists of all the targets in Makefile:
  $gv = $parser->plot_all;
  $gv->as_png('default.png');

  # you can also invoke all the methods inherited from the Makefile::Parser class:
  @targets = $parser->targets;

=head1 DESCRIPTION

This module uses L<Makefile::Parser> to render user's Makefiles via the amazing
L<GraphViz> module. Before I decided to write this thing, there had been already a
CPAN module named L<GraphViz::Makefile> which did the same thing. However, the
pictures generated by L<GraphViz::Makefile> is oversimplified in my opinion, so
a much complex one is still needed.

B<IMPORTANT!>
This stuff is highly experimental and is currently at B<ALPHA> stage, so
production use is strongly discouraged. Anyway, I have the plan to 
improve this stuff unfailingly.

=head1 SAMPLE PICTURES

Browse L<http://search.cpan.org/src/AGENT/Makefile-GraphViz-0.11/samples.html>
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

=item plot($target, ...)

This method is essential to the class. Users invoke this method to plot the specified
Makefile target. If the argument is absent, the default target in the Makefile will
be used. It will return a L<GraphViz> object, on which you can later call the
-E<gt>as_png or -E<gt>as_text method to obtain the final graphical output.

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
with no real files corresponding to them.

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

=back

=head2 EXPORT

None by default.

=head2 INTERNAL FUNCTIONS

Internal functions should not be used directly.

=over

=item gen_id

Generate a unique id for command node.

=item trim_path

Trim the path to a more readable form.

=item trim_cmd

Trim the shell command to a more friendly size.

=item find

If the given element is found in the given list, this
function will return 1; otherwise, a false value is
returned.

=back

=head1 CODE COVERAGE

I use L<Devel::Cover> to test the code coverage of my tests, below is the 
L<Devel::Cover> report on this module test suite.

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    .../lib/Makefile/GraphViz.pm  100.0   90.9   69.0  100.0  100.0  100.0   90.9
    Total                         100.0   90.9   69.0  100.0  100.0  100.0   90.9
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 REPOSITORY

For the very latest version of this module, check out the source from
L<https://svn.berlios.de/svnroot/repos/makefilegv> (Subversion). There is
anonymous access to all.

=head1 BUGS

Please report bugs or send wish-list to
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Makefile-GraphViz>.

=head1 SEE ALSO

L<gvmake>, L<GraphViz>, L<Makefile::Parser>.

=head1 AUTHOR

Agent Zhang, E<lt>agent2002@126.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Agent Zhang.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
