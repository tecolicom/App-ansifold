package App::ansifold;
our $VERSION = "1.12";

use v5.14;
use warnings;

use open IO => 'utf8', ':std';
use Encode;

use Pod::Usage;
use List::Util qw(min);
use Hash::Util qw(lock_keys);
use Text::ANSI::Fold qw(:constants);
use Data::Dumper;

our $DEFAULT_WIDTH    //= 72;
our $DEFAULT_EXPAND   //= 0;
our $DEFAULT_SEPARATE //= "\n";
our $DEFAULT_COLRM    //= 0;

use Getopt::EX::Hashed 'has'; {

    has width     => ' w =s@ ' , default => [];
    has boundary  => '   =s  ' , default => 'none';
    has padding   => '   :s  ' , action => sub {
	$_->{padding} = 1;
	$_->{padchar} = $_[1] if $_[1] ne '';
    };
    has padchar   => '   =s  ' ;
    has ambiguous => '   =s  ' ;
    has paragraph => ' p +   ' , default => 0;
    has separate  => '   =s  ' , default => $DEFAULT_SEPARATE;
    has linebreak => '   =s  ' , alias   => 'lb';
    has runin     => '   =i  ' , min => 1, default => 4;
    has runout    => '   =i  ' , min => 1, default => 4;
    has nonewline => ' n     ' ;
    has smart     => ' s !   ' ;
    has expand    => ' x :-1 ' , default => $DEFAULT_EXPAND;
    has tabstop   => '   =i  ' , min => 1;
    has tabhead   => '   =s  ' ;
    has tabspace  => '   =s  ' ;
    has tabstyle  => '   =s  ' ;
    has discard   => '   =s@ ' , default => [];
    has colrm     => '       ' , default => $DEFAULT_COLRM;
    has help      => ' h     ' ;
    has version   => ' v     ' ;

    has '+boundary'  => any => [ qw(none word space) ];
    has '+ambiguous' => any => [ qw(wide narrow) ] ;

    has '+help' => action => sub {
	pod2usage
	    -verbose  => 99,
	    -sections => [ qw(SYNOPSIS VERSION) ];
    };

    has '+version' => action  => sub {
	print "Version: $VERSION\n";
	exit;
    };

    has '+nonewline' => action  => sub {
	$_->{separate} = "";
    };

    has '+linebreak' =>
	default => LINEBREAK_NONE,
	action => sub {
	    my($name, $value) = @_;
	    $_->{$name} = do {
		local $_ = $value;
		my $v = LINEBREAK_NONE;
		$v   |= LINEBREAK_ALL    if /all/i;
		$v   |= LINEBREAK_RUNIN  if /runin/i;
		$v   |= LINEBREAK_RUNOUT if /runout/i;
		$v;
	    };
    };

    has '+smart' =>
	action => sub {
	    my $smart = $_->{$_[0]} = $_[1];
	    ($_->{boundary}, $_->{linebreak}) = do {
		if ($smart) {
		    ('word', LINEBREAK_ALL);
		} else {
		    ('none', LINEBREAK_NONE);
		}
	    };
    };

} no Getopt::EX::Hashed;

sub run {
    my $app = shift;

    for (@ARGV) {
	$_ = decode 'utf8', $_ unless utf8::is_utf8($_);
    }

    use Getopt::EX::Long qw(:DEFAULT ExConfigure Configure);
    ExConfigure BASECLASS => [ __PACKAGE__, 'Getopt::EX' ];
    Configure "bundling";
    $app->getopt || pod2usage();

    my @width_map;
    my @width_index;

    if ($app->{colrm}) {
	@{$app->{width}} = do {
	    unless (@ARGV > 0 and $ARGV[0] =~ /^\d+$/) {
		"-1";
	    } else {
		my $start = shift(@ARGV) - 1;
		if (@ARGV > 0 and $ARGV[0] =~ /^\d+$/) {
		    my $end = shift(@ARGV);
		    sprintf '%d,-%d,-1', $start, $end - $start;
		} else {
		    sprintf '%d,', $start;
		}
	    }
	}
    }

    use Getopt::EX::Numbers;
    my $numbers = Getopt::EX::Numbers->new;

    my @width = do {
	map {
	    if    (/^$/)      { 0  }			# empty
	    elsif (/^-?\d+$/) { $_ }			# number
	    elsif (/^(-?[-\d:]+) (?:\{(\d+)\})? $/x) {	# a:b:c:d{e}
		($numbers->parse($1)->sequence) x ($2 // 1);
	    }
	    else { die "$_: width format error.\n" }
	}
	map { split /,/, $_, -1 }
	@{$app->{width}};
    };

    $app->{width} = do {
	if    (@width == 0) { $DEFAULT_WIDTH }
	elsif (@width == 1) { $width[0] }
	else {
	    my @map = [ (int(pop @width)) x 2 ];
	    unshift @map, map { [ $_ < 0 ? (-$_, 0) : ($_, 1) ] } @width;
	    @width = map { $_->[0] } @map;
	    @width_index = grep { $map[$_][1] } 0 .. $#map;
	    \@width;
	}
    };

    if ($app->{expand} > 0) {
	$app->{tabstop} = $app->{expand};
    }

    use charnames ':loose';
    for (@{$app}{qw(tabhead tabspace)}) {
	defined && length > 1 or next;
	$_ = charnames::string_vianame($_) || die "$_: invalid name\n";
    }

    my $fold = Text::ANSI::Fold->new(
	map  { $_ => $app->{$_} }
	grep { defined $app->{$_} }
	qw(width boundary padding padchar ambiguous
	linebreak runin runout
	expand tabstyle tabstop tabhead tabspace discard)
	);

    my $separator = do {
	$app->{separate} =~ s{ ( \\ (.) ) } {
	{ '\\' => '\\', n => "\n" }->{$2} // $1
	}gexr;
    };

    while (<>) {
	my $chomped = chomp;
	my @chops = $fold->text($_)->chops;
	if (@width_index > 0) {
	    @chops = grep { defined } @chops[@width_index];
	}
	print join $separator, @chops;
	print "\n" if $chomped;
	print "\n" x $app->{paragraph} if $app->{paragraph} > 0;
    }

    return 0;
}

1;

__END__

=head1 NAME

App::ansifold - fold command handling ANSI terminal sequences

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2018- Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
