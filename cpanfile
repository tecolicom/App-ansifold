requires 'perl' => '5.016';

requires 'Unicode::EastAsianWidth';
requires 'Text::ANSI::Fold' => '2.2102';
requires 'Text::ANSI::Fold::Util' => '1.01';
requires 'Getopt::EX' => '2.1.2';
requires 'Getopt::EX::Hashed' => '1.05';
requires 'Getopt::EX::RPN';
requires 'Term::ReadKey';

on 'test' => sub {
    requires 'Test::More' => '0.98';
};

