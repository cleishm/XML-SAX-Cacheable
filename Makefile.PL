use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::SAX::Cacheable',
    'VERSION_FROM'	=> 'lib/XML/SAX/Cacheable.pm', # finds $VERSION
    'AUTHOR'		=> 'Chris Leishman <chris@leishman.org>',
    'PREREQ_PM'		=> {
	XML::SAX			=> 0.12,
	XML::SAX::Writer		=> 0.42,
	XML::Filter::Recorder		=> 1.00,
	XML::Filter::Tee		=> 0.1,
	XML::SAX::EventMethodMaker	=> 0.1,
	Storable			=> 1.00,
	Test::More			=> 0.47,
	Cache				=> 2.01,
    },
);
