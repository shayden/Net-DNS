# $Id: 04-packet.t,v 1.4 2000/11/19 06:11:00 mfuhr Exp mfuhr $

BEGIN { $| = 1; print "1..19\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS;

$loaded = 1;
print "ok 1\n";

$domain = "example.com";
$type   = "MX";
$class  = "IN";

#------------------------------------------------------------------------------
# Make sure we can create a DNS packet.
#------------------------------------------------------------------------------

$packet = Net::DNS::Packet->new($domain, $type, $class);
print "not " unless defined $packet;
print "ok 2\n";

print "not " unless defined $packet->header;
print "ok 3\n";

@question = $packet->question;
print "not " unless @question  && (@question == 1);
print "ok 4\n";

@answer = $packet->answer;
print "not " if @answer;
print "ok 5\n";

@authority = $packet->authority;
print "not " if @authority;
print "ok 6\n";

@additional = $packet->additional;
print "not " if @additional;
print "ok 7\n";

#------------------------------------------------------------------------------
# Make sure we can add records to the packet.
#------------------------------------------------------------------------------

$packet->push("answer", Net::DNS::RR->new(
	Name    => "a1.example.com",
	Type    => "A",
	Address => "10.0.0.1"));
print "not " unless $packet->header->ancount == 1;
print "ok 8\n";

$packet->push("answer", Net::DNS::RR->new(
	Name    => "a2.example.com",
	Type    => "A",
	Address => "10.0.0.2"));
print "not " unless $packet->header->ancount == 2;
print "ok 9\n";

$packet->push("authority", Net::DNS::RR->new(
	Name    => "a3.example.com",
	Type    => "A",
	Address => "10.0.0.3"));
print "not " unless $packet->header->nscount == 1;
print "ok 10\n";

$packet->push("authority", Net::DNS::RR->new(
	Name    => "a4.example.com",
	Type    => "A",
	Address => "10.0.0.4"));
print "not " unless $packet->header->nscount == 2;
print "ok 11\n";

$packet->push("additional", Net::DNS::RR->new(
	Name    => "a5.example.com",
	Type    => "A",
	Address => "10.0.0.5"));
print "not " unless $packet->header->adcount == 1;
print "ok 12\n";

$packet->push("additional", Net::DNS::RR->new(
	Name    => "a6.example.com",
	Type    => "A",
	Address => "10.0.0.6"));
print "not " unless $packet->header->adcount == 2;
print "ok 13\n";

#------------------------------------------------------------------------------
# Make sure we can convert a packet to data and back to a packet.
#------------------------------------------------------------------------------

$data1 = $packet->data;
$data2 = $packet->data;
print "not " unless $data1 eq $data2;
print "ok 14\n";

$packet2 = Net::DNS::Packet->new(\$data1);
print "not " unless defined $packet2;
print "ok 15\n";

print "not " unless $packet2->header->qdcount == 1;
print "ok 16\n";

print "not " unless $packet2->header->ancount == 2;
print "ok 17\n";

print "not " unless $packet2->header->nscount == 2;
print "ok 18\n";

print "not " unless $packet2->header->adcount == 2;
print "ok 19\n";
