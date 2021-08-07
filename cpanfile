requires 'perl' => '5.016';

requires 'Text::ANSI::Fold' => '2.11';
requires 'Getopt::EX' => 'v1.24.1';
requires 'Getopt::EX::Hashed' => '0.9906';

on 'test' => sub {
    requires 'Test::More' => '0.98';
    requires 'Command::Runner';
};

