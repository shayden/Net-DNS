# $Id: 01-resolver.t,v 1.1 1997/02/03 05:19:17 mfuhr Exp $

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::Resolver;

$loaded = 1;
print "ok 1\n";

$res = new Net::DNS::Resolver;
print "not " unless defined($res);
print "ok 2\n";
