# $Id: 04-packet.t,v 1.1 1997/02/03 05:19:46 mfuhr Exp $

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::Packet;

$loaded = 1;
print "ok 1\n";

$domain = "foo.com";
$type   = "MX";
$class  = "IN";

$packet = new Net::DNS::Packet($domain, $type, $class);
print "not " unless defined($packet);
print "ok 2\n";

print "not " unless defined($packet->header);
print "ok 3\n";

@question = $packet->question;
print "not " unless defined(@question) && ($#question == 0);
print "ok 4\n";

@answer = $packet->answer;
print "not " if defined(@answer);
print "ok 5\n";

@authority = $packet->authority;
print "not " if defined(@authority);
print "ok 6\n";

@additional = $packet->additional;
print "not " if defined(@additional);
print "ok 7\n";
