#------------------------------------------------------------------------------
# Makefile.PL for Net::DNS
#
# $Id: Makefile.PL,v 1.8 2000/11/19 05:48:43 mfuhr Exp mfuhr $
#------------------------------------------------------------------------------

BEGIN {
    require 5.006;
}

use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'         => 'Net::DNS',
	'VERSION_FROM' => 'lib/Net/DNS.pm',
	'AUTHOR'       => 'Michael Fuhr <mike@fuhr.org>',
	'ABSTRACT'     => 'Perl DNS resolver module',
	'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
	'PREREQ_PM'    => {
			    FileHandle       => 2.00,
			    IO::Socket       => 1.26,
			    IO::Select       => 1.14,
			    Socket           => 1.72,
			    MIME::Base64     => 2.11,
			    Digest::MD5      => 2.12,
			    Digest::HMAC_MD5 => 1.00,
			  },
);
