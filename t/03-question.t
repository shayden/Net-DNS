# $Id: 03-question.t,v 1.3 2000/11/19 06:10:19 mfuhr Exp mfuhr $

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS;

$loaded = 1;
print "ok 1\n";

$domain = "example.com";
$type   = "MX";
$class  = "IN";

$question = Net::DNS::Question->new($domain, $type, $class);
print "not " unless defined($question);
print "ok 2\n";

print "not " unless $question->qname eq $domain;
print "ok 3\n";

print "not " unless $question->qtype eq $type;
print "ok 4\n";

print "not " unless $question->qclass eq $class;
print "ok 5\n";
