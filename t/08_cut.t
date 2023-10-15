use v5.14;
use warnings;
use utf8;

use Data::Dumper;
use Test::More;

use Text::ParseWords qw(shellwords);

use lib '.';
use t::Util;

##
## --cut
##

test
    option => "-c 1",
    stdin  => "1234567890",
    expect => "1";

test
    option => "-c 1,3,5,7,9",
    stdin  => "1234567890",
    expect => "13579";

test
    option => "-c 3-5",
    stdin  => "1234567890",
    expect => "345";

test
    option => "-c 1-3,5-7",
    stdin  => "1234567890",
    expect => "123567";

test
    option => "-c -3",
    stdin  => "1234567890",
    expect => "123";

test
    option => "-c 5-",
    stdin  => "1234567890",
    expect => "567890";

done_testing;
