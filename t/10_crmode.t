use v5.14;
use warnings;
use utf8;

use Test::More;
use Text::ParseWords qw(shellwords);

use lib '.';
use t::Util;

##
## crmode - single line
##

test
    option => "--crmode -w80",
    stdin  => "hello\rworld\rtest\n",
    expect => "hello world test\n";

test
    option => "--crmode -w80",
    stdin  => "日本語\rテスト\rです\n",
    expect => "日本語テストです\n";

# mixed
test
    option => "--crmode -w80",
    stdin  => "hello\r世界\rtest\n",
    expect => "hello 世界 test\n";

##
## crmode - multiple lines
##

test
    option => "--crmode -w80",
    stdin  => "hello\rworld\nfoo\rbar\n",
    expect => "hello world\nfoo bar\n";

test
    option => "--crmode -w80",
    stdin  => "日本語\rテスト\n英語\rEnglish\n",
    expect => "日本語テスト\n英語 English\n";

##
## crmode with folding (output uses \r as separator)
##

test
    option => "--crmode -w20",
    stdin  => "hello\rworld\rthis\ris\ra\rtest\n",
    expect => "hello world this is \ra test\n";

test
    option => "--crmode -sw20",
    stdin  => "hello\rworld\rthis\ris\ra\rtest\n",
    expect => "hello world this is \ra test\n";

# Japanese - no trailing space
test
    option => "--crmode -w20",
    stdin  => "日本語\rテスト\r文字列\n",
    expect => "日本語テスト文字列\n";

##
## no cr - should pass through unchanged
##

test
    option => "--crmode -w80",
    stdin  => "hello world\n",
    expect => "hello world\n";

test
    option => "--crmode -w80",
    stdin  => "line1\nline2\nline3\n",
    expect => "line1\nline2\nline3\n";

##
## --no-crmode should not affect separator
##

test
    option => "--no-crmode -w5",
    stdin  => "hello world\n",
    expect => "hello\n worl\nd\n";

done_testing;
