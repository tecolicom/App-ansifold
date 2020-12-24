requires 'perl' => '5.016';

requires 'Text::ANSI::Fold' => '2.08';
requires 'Getopt::EX' => 'v1.21.1';

on 'test' => sub {
    requires 'Test::More' => '0.98';
};

