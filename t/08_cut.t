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
    option => "-nc 1",
    stdin  => "1234567890",
    expect => "1";

test
    option => "-nc 1,3,5,7,9",
    stdin  => "1234567890",
    expect => "13579";

test
    option => "-nc 3-5",
    stdin  => "1234567890",
    expect => "345";

test
    option => "-nc 1-3,5-7",
    stdin  => "1234567890",
    expect => "123567";

test
    option => "-nc -3",
    stdin  => "1234567890",
    expect => "123";

test
    option => "-nc 5-",
    stdin  => "1234567890",
    expect => "567890";

done_testing;
