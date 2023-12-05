package App::ansifold;
our $VERSION = "1.24";

use v5.14;
use warnings;

use open IO => 'utf8', ':std';
use Encode;

use Pod::Usage;
use List::Util qw(min);
use Hash::Util qw(lock_keys);
use Text::ANSI::Fold qw(:constants);
use Text::ANSI::Fold::Util qw(ansi_width); {
    Text::ANSI::Fold->configure(expand => 1);
}
use Unicode::EastAsianWidth;
use Data::Dumper;

our $DEFAULT_WIDTH    //= 72;
our $DEFAULT_SEPARATE //= "\n";
our $DEFAULT_EXPAND   //= 0;
our $DEFAULT_COLRM    //= 0;
our $DEFAULT_CUT      //= 0;

use Getopt::EX::Hashed 'has'; {

    Getopt::EX::Hashed->configure(DEFAULT => [ is => 'rw' ]);

    has width     => ' w =s@ ' , default => [];
    has boundary  => '   =s  ' , default => 'none';
    has padding   => '   :s  ' , action => sub {
	$_->padding = 1;
	$_->padchar = $_[1] if $_[1] ne '';
    };
    has padchar    => '   =s  ' ;
    has prefix     => '   =s  ' ;
    has autoindent => '   =s  ' ;
    has indentchar => '   =s  ' , default => ' ';
    has ambiguous  => '   =s  ' ;
    has paragraph  => ' p +   ' , default => 0;
    has refill     => ' r +   ' , default => 0;
    has separate   => '   =s  ' ;
    has linebreak  => '   =s  ' , alias   => 'lb';
    has runin      => '   =i  ' , min => 0, default => 4;
    has runout     => '   =i  ' , min => 0, default => 4;
    has run        => '   =i  ' , min => 0;
    has nonewline  => ' n     ' ;
    has smart      => ' s !   ' ;
    has expand     => ' x :-1 ' , default => $DEFAULT_EXPAND;
    has tabstop    => '   =i  ' , min => 1;
    has tabhead    => '   =s  ' ;
    has tabspace   => '   =s  ' ;
    has tabstyle   => '   =s  ' ;
    has discard    => '   =s@ ' , default => [];
    has colrm      => '       ' , default => $DEFAULT_COLRM;
    has cut        => ' c =s  ' ;
    has debug      => ' d     ' ;
    has help       => ' h     ' ;
    has version    => ' v     ' ;

    has '+boundary'  => any => [ qw(none word space) ];
    has '+ambiguous' => any => [ qw(wide narrow) ] ;

    has '+help' => sub {
	pod2usage
	    -verbose  => 99,
	    -sections => [ qw(SYNOPSIS VERSION) ];
    };

    has '+version' => sub {
	print "Version: $VERSION\n";
	exit;
    };

    has '+nonewline' => sub {
	$_->separate = "";
    };

    has '+linebreak' =>
	default => LINEBREAK_NONE,
	action => sub {
	    my($name, $value) = @_;
	    $_->$name = do {
		local $_ = $value;
		my $v = LINEBREAK_NONE;
		$v   |= LINEBREAK_ALL    if /all/i;
		$v   |= LINEBREAK_RUNIN  if /runin/i;
		$v   |= LINEBREAK_RUNOUT if /runout/i;
		$v;
	    };
	};

    ### --run
    has '+run' => sub {
	$_->runin = $_->runout = $_[1];
    };

    has '+smart' => sub {
	my $smart = $_->{$_[0]} = $_[1];
	($_->boundary, $_->linebreak) = do {
	    if ($smart) {
		('word', LINEBREAK_ALL);
	    } else {
		('none', LINEBREAK_NONE);
	    }
	};
    };

    # internal use
    has width_index => default => [];
    has indent_pat => ;
    has min_width => ;

} no Getopt::EX::Hashed;

sub perform {
    my $app = shift;
    local @ARGV = @_;
    $app->options->params->doit;
    return 0;
}

sub options {
    my $app = shift;

    for (@ARGV) {
	$_ = decode 'utf8', $_ unless utf8::is_utf8($_);
    }

    use Getopt::EX::Long qw(:DEFAULT ExConfigure Configure);
    ExConfigure BASECLASS => [ __PACKAGE__, 'Getopt::EX' ];
    Configure "bundling";
    $app->getopt || pod2usage();

    ## --colrm
    if ($app->colrm) {
	$app->separate //= '';
	my @params;
	while (@ARGV > 0 and $ARGV[0] =~ /^\d+$/) {
	    push @params, shift @ARGV;
	}
	@{$app->width} = colrm_to_width(@params);
    }
    ## --cut
    elsif ($app->cut) {
	$app->separate //= '';
	@{$app->width} = cut_to_width($app->cut);
    }

    if ($app->expand > 0) {
	$app->tabstop = $app->expand;
    }

    $app->separate //= $DEFAULT_SEPARATE;

    use charnames ':loose';
    for (@{$app}{qw(tabhead tabspace)}) {
	defined && length > 1 or next;
	$_ = charnames::string_vianame($_) || die "$_: invalid name\n";
    }

    if (my $indent = $app->autoindent) {
	$app->indent_pat = qr/$indent/;
    }

    return $app;
}

sub params {
    my $app = shift;

    use Getopt::EX::Numbers;
    my $numbers = Getopt::EX::Numbers->new;

    my @width = do {
	map {
	    if    (/^$/)      { 0  }			# empty
	    elsif (/^-?\d+$/) { $_ }			# number
	    elsif (/^(-?[-\d:]+) (?:\{(\d+)\})? $/x) {	# a:b:c:d{e}
		($numbers->parse($1)->sequence) x ($2 // 1);
	    }
	    elsif (/^=(.*)/) {
		require Getopt::EX::RPN;
		int Getopt::EX::RPN::rpn_calc(terminal_width(), $1);
	    }
	    else { die "$_: width format error.\n" }
	}
	map { split /,/, $_, -1 }
	@{$app->width};
    };

    $app->width = do {
	if    (@width == 0) { $DEFAULT_WIDTH }
	elsif (@width == 1) { $width[0] }
	else {
	    my @map = map [ abs $_ => $_ >= 0 ], @width;
	    $map[-1] = [ $width[-1] => $width[-1] ];
	    @width = map $_->[0], @map;
	    $app->width_index = [ grep { $map[$_][1] != 0 } keys @map ];
	    \@width;
	}
    };

    $app->min_width = ref $app->width ? min @{$app->width} : $app->width;

    return $app;
}

sub doit {
    my $app = shift;

    my $fold = Text::ANSI::Fold->new(
	map  { $_ => $app->$_ }
	grep { defined $app->$_ }
	qw(width boundary padding padchar prefix ambiguous
	   linebreak runin runout
	   expand tabstyle tabstop tabhead tabspace discard)
    );

    my $separator = eval sprintf(qq["%s"], $app->separate) // do {
	warn $@ =~ s/ at .*//r;
	$DEFAULT_SEPARATE;
    };

    my @index = @{$app->width_index};

    local $/ = "\n\n" if $app->refill;
    while (<>) {
	if (s/\A(\n+)//) {
	    print $1;
	    next if length == 0;
	}
	# chomp() does not remove single "\n" when $/ is "\n\n"
	my $chomped = s/(\n+)\z// ? length $1 : 0;
	fill_paragraph() if $app->refill;
	my @opt;
	if ($app->{indent_pat} && /^$app->{indent_pat}/p) {
	    my $indent = ansi_width ${^MATCH};
	    if ($indent >= $app->min_width) {
		die sprintf("%s\n%s\n%s\n", $_, ("^" x $indent),
			    "ERROR: Autoindent pattern is longer than folding width.");
	    }
	    my $prefix = $app->indentchar x $indent;
	    $fold->configure(prefix => $prefix);
	}
	my @chops = $fold->text($_)->chops;
	@chops = grep { defined } @chops[@index] if @index > 0;
	print join $separator, @chops;
	print "\n" x $chomped if $chomped;
	print "\n" x $app->paragraph if $app->paragraph > 0;
    }

    return $app;
}

sub fill_paragraph {
    s/(?<=\p{InFullwidth})\R(?=\p{InFullwidth})//g;
    s/[ ]*\R[ ]*/ /g;
}

sub terminal_width {
    use Term::ReadKey;
    my $default = 80;
    my @size;
    if (open my $tty, ">", "/dev/tty") {
	# Term::ReadKey 2.31 on macOS 10.15 has a bug in argument handling
	# and the latest version 2.38 fails to install.
	# This code should work on both versions.
	@size = GetTerminalSize $tty, $tty;
    }
    $size[0] or $default;
}

sub colrm_to_width {
    my @width;
    my $pos = 0;
    while (my($start, $end) = splice @_, 0, 2) {
	$pos < $start or die "$start: invalid arg\n";
	$start--;
	push @width,
	    $start - $pos,
	    defined $end ? $start - $end : '';
	$pos = $end // last;
    }
    push @width, -1 if @width == 0 or $width[-1] ne '';
    join ',', @width;
}

sub cut_to_width {
    my $list = shift;
    my @params = split /[\s,]+/, $list;
    my @width;
    my $pos = 1;
    for (@params) {
	next if $_ eq '';
	my($start, $end) =
	    /^(\d+)$/       ? ( $1,   $1 ) :
	    /^-(\d+)/       ? ( $pos, $1 ) :
	    /^(\d+)-$/      ? ( $1,   -1 ) :
	    /^(\d+)-(\d+)$/ ? ( $1,   $2 ) : die "$list: format error";
	$pos <= $start or die "$start: invalid arg\n";
	if ($start > $pos) {
	    push @width, $pos - $start;
	}
	if ($end < 0) {
	    push @width, -1;
	    last;
	} else {
	    push @width, $end - $start + 1;
	}
	$pos = $end + 1;
    }
    push @width, 0 if $width[-1] != -1;
    join ',', @width;
}

1;

__END__

=encoding utf-8

=head1 NAME

App::ansifold - fold command handling ANSI terminal sequences

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright ©︎ 2018- Kazumasa Utashiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
