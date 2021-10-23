use v5.14;
use warnings;
use utf8;

use Data::Dumper;
use Test::More;

use Text::ParseWords qw(shellwords);

use lib '.';
use t::Runner;

sub test {
    my %arg = @_;
    my @opts = shellwords($arg{option});
    my $fold = Runner->new('ansifold', @opts);
    $fold->setstdin($arg{stdin});
    is ($fold->run->{stdout}, $arg{expect}, $arg{option});
}

##
## separate
##

test
    option => "-w10",
    stdin => "0123456789" x 5,
    expect => join("\n", ("0123456789") x 5)
    ;

test
    option => "-w10 -n",
    stdin => "0123456789" x 5,
    expect => join("", ("0123456789") x 5)
    ;

test
    option => "-w10 --separate ''",
    stdin => "0123456789" x 5,
    expect => join("", ("0123456789") x 5)
    ;

test
    option => "-w10 --separate :",
    stdin => "0123456789" x 5,
    expect => join(":", ("0123456789") x 5)
    ;

##
## colrm
##

test
    option => "-n --colrm 4",
    stdin => "1234567890",
    expect => "123",
    ;

test
    option => "-n --colrm 4 7",
    stdin => "1234567890",
    expect => "123890",
    ;

done_testing;
