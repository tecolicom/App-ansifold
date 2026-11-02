use v5.14;
use warnings;
use utf8;

use Test::More;
use Text::ParseWords qw(shellwords);

use lib '.';
use t::Util;

##
## --autoindent: the matched prefix becomes spaces of the same width
##

my $list  = "- item one is long enough to be folded somewhere";
my $quote = "> quote one is long enough to be folded somewhere";
my $both  = "> - quoted item is long enough to be folded here";
my $nest  = "> > nested quote is long enough to be folded here";
my $deep  = "  > indented quote is long enough to be folded here";
my $pat   = q{'^\h*((?:>\h?)*)(?:[-*]\h+)?'};

test
    option => "-w 30 -s --autoindent $pat",
    stdin  => "$list\n",
    expect => "- item one is long enough to \n  be folded somewhere\n";

##
## --keepindent: the whole match is repeated
##

test
    option => "-w 30 -s --autoindent $pat --keepindent",
    stdin  => "$quote\n",
    expect => "> quote one is long enough to \n> be folded somewhere\n";

test
    option => "-w 30 -s --autoindent $pat --keepindent",
    stdin  => "$list\n",
    expect => "- item one is long enough to \n- be folded somewhere\n";

##
## --keepindent=group: only the captured part is repeated, the rest of
## the match becomes spaces
##

test
    option => "-w 30 -s --autoindent $pat --keepindent=group",
    stdin  => "$list\n",
    expect => "- item one is long enough to \n  be folded somewhere\n";

test
    option => "-w 30 -s --autoindent $pat --keepindent=group",
    stdin  => "$quote\n",
    expect => "> quote one is long enough to \n> be folded somewhere\n";

test
    option => "-w 30 -s --autoindent $pat --keepindent=group",
    stdin  => "$both\n",
    expect => "> - quoted item is long enough \n>   to be folded here\n";

test
    option => "-w 30 -s --autoindent $pat --keepindent=group",
    stdin  => "$nest\n",
    expect => "> > nested quote is long \n> > enough to be folded here\n";

test
    option => "-w 30 -s --autoindent $pat --keepindent=group",
    stdin  => "$deep\n",
    expect => "  > indented quote is long \n  > enough to be folded here\n";

# a marker colored the way mdee does it (the SGR sequences are in the
# group) keeps its color; the list marker outside the group is blanked
test
    option => "-w 30 -s --autoindent '^((?:(?:\\e\\[[\\d;]*m)*>\\h?)+(?:\\e\\[[\\d;]*m)*)(?:[-*]\\h+)?' --keepindent=group",
    stdin  => "\e[1m> \e[m- colored item is long enough to fold\n",
    expect => "\e[1m> \e[m- colored item is long \n\e[1m> \e[m  enough to fold\n";

# a pattern without a group under =group behaves like plain autoindent
test
    option => "-w 30 -s --autoindent '^(?:>\\h?)+' --keepindent=group",
    stdin  => "$quote\n",
    expect => "> quote one is long enough to \n  be folded somewhere\n";

# --keepindent=all is the bare --keepindent
test
    option => "-w 30 -s --autoindent $pat --keepindent=all",
    stdin  => "$quote\n",
    expect => "> quote one is long enough to \n> be folded somewhere\n";

##
## --keepindent=named: only named groups are kept; plain parentheses
## group without capturing, so (?:...) is not needed
##

my $named = q{'^(?<q>(>\h?)*)([-*]\h+)?'};

test
    option => "-w 30 -s --autoindent $named --keepindent=named",
    stdin  => "$both\n",
    expect => "> - quoted item is long enough \n>   to be folded here\n";

test
    option => "-w 30 -s --autoindent $named --keepindent=named",
    stdin  => "$list\n",
    expect => "- item one is long enough to \n  be folded somewhere\n";

# the same pattern under =group keeps the plain parentheses too
test
    option => "-w 30 -s --autoindent $named --keepindent=group",
    stdin  => "$both\n",
    expect => "> - quoted item is long enough \n> - to be folded here\n";

done_testing;
