# $Id: 02-header.t,v 1.3 2000/11/19 06:10:00 mfuhr Exp mfuhr $

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS;

$loaded = 1;
print "ok 1\n";

$header = Net::DNS::Header->new;
print "not " unless defined($header);
print "ok 2\n";
