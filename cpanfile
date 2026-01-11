requires 'perl' => '5.016';

requires 'Unicode::EastAsianWidth';
requires 'Text::ANSI::Fold' => '2.31';
requires 'Text::ANSI::Fold::Util' => '1.05';
requires 'Getopt::EX' => '2.2.1';
requires 'Getopt::EX::Hashed' => '1.06';
requires 'Getopt::EX::RPN';
requires 'Term::ReadKey';

on 'test' => sub {
    requires 'Test::More' => '0.98';
};

