# $Id: 03-question.t,v 1.1 1997/02/03 05:19:37 mfuhr Exp $

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::Question;

$loaded = 1;
print "ok 1\n";

$domain = "foo.com";
$type   = "MX";
$class  = "IN";

$question = new Net::DNS::Question($domain, $type, $class);
print "not " unless defined($question);
print "ok 2\n";

print "not " unless $question->qname eq $domain;
print "ok 3\n";

print "not " unless $question->qtype eq $type;
print "ok 4\n";

print "not " unless $question->qclass eq $class;
print "ok 5\n";
