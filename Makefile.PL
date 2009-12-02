use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'HTML::Filter::Callbacks',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/HTML/Filter/Callbacks.pm',
    ABSTRACT_FROM => 'lib/HTML/Filter/Callbacks.pm',
    PREREQ_PM => {
        'HTML::Parser'        => '3',
        'Test::More'          => '0.47',
        'Test::UseAllModules' => '0.10',
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.31
        ? ( LICENSE => 'perl' )
        : ()
    ),
);
