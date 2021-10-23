use v5.14;
use warnings;

use Data::Dumper;
use lib '.';
use t::Runner;

$ENV{PERL5LIB} = join ':', @INC;

sub ansifold {
    Runner->new('ansifold', @_)->run;
}

1;
