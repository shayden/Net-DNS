# $Id: 02-header.t,v 1.1 1997/02/03 05:19:27 mfuhr Exp $

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::Header;

$loaded = 1;
print "ok 1\n";

$header = new Net::DNS::Header;
print "not " unless defined($header);
print "ok 2\n";
