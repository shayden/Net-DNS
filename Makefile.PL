# $Id: Makefile.PL,v 1.4 1997/07/06 16:43:35 mfuhr Exp $

# Check for required modules (borrowed from libwww).
$| = 1;
my $missing_modules = 0;

print "Checking for IO::Socket...";
eval {
	require IO::Socket;
	IO::Socket->require_version('1.15');
};
if ($@) {
	print "failed\n";
	$missing_modules++;
	print <<"AMEN";

ERROR: $@
IO::Socket is required but wasn't found.  You must install the IO-1.15
module to use Net::DNS.

AMEN
}
else {
    print "ok\n";
}

if ($missing_modules) {
	die <<"AMEN";
Missing modules can be obtained from the Comprehensive Perl Archive
Network (CPAN) at <URL:http://www.perl.org/CPAN/>.

*** You can't use Net::DNS until any missing modules are installed ***

AMEN
}

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Net::DNS',
    'VERSION_FROM'	=> 'lib/Net/DNS.pm',
    'dist'		=> { COMPRESS => 'gzip', SUFFIX => 'gz' },	
);
