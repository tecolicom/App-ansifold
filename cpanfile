requires 'perl' => '5.016';

requires 'Unicode::EastAsianWidth';
requires 'Text::ANSI::Fold' => '2.2701';
requires 'Text::ANSI::Fold::Util' => '1.02';
requires 'Getopt::EX' => '2.1.4';
requires 'Getopt::EX::Hashed' => '1.0503';
requires 'Getopt::EX::RPN';
requires 'Term::ReadKey';

on 'test' => sub {
    requires 'Test::More' => '0.98';
};

