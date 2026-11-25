use v5.14;
use warnings;
use utf8;

use Test::More;

use lib '.';
use t::Runner;

# The commands ansicolrm, ansicut and ansifold are the functions of
# App::ansifold, which set their defaults by local variables: the
# defaults of the options have to be taken when the function is
# called, not when the module is loaded.

use App::ansifold qw(ansifold ansicolrm ansicut ansiexpand);

$ENV{PERL5LIB} = join ':', @INC;

sub run {
    my($func, $stdin, @opts) = @_;
    my $runner = Runner->new(sub { $func->(@opts) });
    $runner->setstdin($stdin)->run;
    $runner->{stdout};
}

is(run(\&ansicolrm, "1234567890\n", 4),    "123\n",    'ansicolrm 4');
is(run(\&ansicolrm, "1234567890\n", 4, 7), "123890\n", 'ansicolrm 4 7');
is(run(\&ansicolrm, "1234567890\n", 2, 3), "14567890\n", 'ansicolrm 2 3');
is(run(\&ansicut,   "1234567890\n", '-c', '3-5'), "345\n", 'ansicut -c 3-5');
is(run(\&ansiexpand, "a\tb\n"), "a       b\n", 'ansiexpand: tabs are expanded');
is(run(\&ansifold,  "1234567890\n", '-w', 4), "1234\n5678\n90\n", 'ansifold -w 4');

# after ansicolrm, the defaults are those of ansifold again
is(run(sub { ansicolrm(4); print "colrm=", App::ansifold->new->colrm, "\n" }, "1234567890\n"),
   "123\ncolrm=0\n", 'ansicolrm, and then the defaults of ansifold');

done_testing;
