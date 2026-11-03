use v5.14;
use warnings;
use utf8;

use Test::More;
use Text::ParseWords qw(shellwords);

use lib '.';
use t::Util;

my $text = "aaaa bbbbb, cccc\n";

test
    option => "-w 10 --lb=all",
    stdin  => $text,
    expect => "aaaa bbbbb, \ncccc\n";

test
    option => "-w 10 --lb=all --trim",
    stdin  => $text,
    expect => "aaaa bbbbb,\ncccc\n";

test
    option => "-w 10 -s",
    stdin  => $text,
    expect => "aaaa bbbbb,\ncccc\n";

test
    option => "-w 10 -s --no-trim",
    stdin  => $text,
    expect => "aaaa bbbbb, \ncccc\n";

test
    option => "-w 10 --no-trim -s",
    stdin  => $text,
    expect => "aaaa bbbbb,\ncccc\n";

test
    option => "--crmode -w 10 -s",
    stdin  => $text,
    expect => "aaaa bbbbb,\rcccc\n";

test
    option => "-w 10 -s --no-smart",
    stdin  => $text,
    expect => "aaaa bbbbb\n, cccc\n";

test
    option => "-w 10 -s --padding",
    stdin  => "aaaa bbbbb cccc\n",
    expect => "aaaa bbbbb\ncccc      \n";

test
    option => "-w 20 -s",
    stdin  => "aaaa \n",
    expect => "aaaa \n";

done_testing;
