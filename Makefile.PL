require 5.004;
use strict;
use Config;

my $path;

print '-' x 65, "\n";
print "Errors.pm installer...\n\n";

my %opts =
    ('NAME' => 'Errors',
     'VERSION_FROM' => 'lib/Errors/Errors.pm',
     'dist'    => { 'SUFFIX' => '.gz',
		    'COMPRESS' => 'gzip -9f' },     
     );
$opts{'AUTHOR'} = 'Julian Lishev (julian@proscriptum.com)';

require ExtUtils::MakeMaker;
ExtUtils::MakeMaker::WriteMakefile(%opts);
my $make = $^O =~ /Win/si ? 'nmake' : 'make';
print "\n\nDone...\n";
print "\nPlease run follow commands: \n";
print "$make\n";
print "$make test\n";
print "$make install\n";
print "$make clean\n";