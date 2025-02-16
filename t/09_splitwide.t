use v5.14;
use warnings;
use utf8;
use open IO => ':utf8', ':std';

use Data::Dumper;
use Test::More;

use lib '.';
use t::Util;

sub folded {
    my @option = @_;
    my $fold = ansifold(@option, "t/04_linebreak.txt");
    $fold->run->{stdout} =~ s/\n\z//r;
}

my @option;

@option = qw (--linebreak=all);
is(folded("-w1," , @option), "「",             "-w1");
is(folded("-w2," , @option), "「",             "-w2");
is(folded("-w3," , @option), "「",             "-w3");
is(folded("-w7,3," , @option), "「吾輩\nは",   "-w7,3");

my($l, $r) = ( '◖', '◗' );

@option = qw (--splitwide --linebreak=all);
is(folded("-w1," , @option), "$l",                   "--splitwide -w1");
is(folded("-w2," , @option), "「",                   "--splitwide -w2");
is(folded("-w3," , @option), "「$l",                 "--splitwide -w3");
is(folded("-w7,3," , @option), "「吾輩${l}\n${r}猫", "--splitwide -w7,3");

done_testing;
