package Net::DNS;

=head1 NAME

Net::DNS - Perl interface to the DNS resolver

=head1 DESCRIPTION

Net::DNS is a collection of Perl modules to interface with the Domain
Name System (DNS) resolver.  It allows the programmer to perform
queries that are beyond the capabilities of C<gethostbyname>
and C<gethostbyaddr>.

=head2 Resolver Objects

A resolver object is an instance of the C<Net::DNS::Resolver> class.
A program can have multiple resolver objects, each maintaining
its own state information such as the nameservers to be queried, 
whether recursion is desired, etc.

=head2 Packet Objects

C<Net::DNS::Resolver> queries return C<Net::DNS::Packet> objects.  Packet
objects have five sections:

=over 3

=item *

The header section, a C<Net::DNS::Header> object.

=item *

The question section, a list of C<Net::DNS::Question> objects.

=item *

The answer section, a list of C<Net::DNS::RR> objects.

=item *

The authority section, a list of C<Net::DNS::RR> objects.

=item *

The additional section, a list of C<Net::DNS::RR> objects.

=back

=head2 Header Objects

C<Net::DNS::Header> objects represent the header section of a DNS packet.

=head2 Question Objects

C<Net::DNS::Question> objects represent the query section of a DNS packet.

=head2 RR Objects

C<Net::DNS::RR> is the base class for DNS resource record (RR) objects in
the answer, authority, and additional sections of a DNS packet.

=head1 EXAMPLES

These examples show how to use the DNS modules:

  # Look up a host's addresses.
  use Net::DNS::Resolver;
  $res = new Net::DNS::Resolver;
  $query = $res->search("foo.bar.com");
  foreach $record ($query->answer) {
      print $record->address, "\n";
  }

  # Find the nameservers for a domain.
  use Net::DNS::Resolver;
  $res = new Net::DNS::Resolver;
  $query = $res->query("foo.com", "NS");
  foreach $nameserver ($query->answer) {
      print $nameserver->nsdname, "\n";
  }

  # Find the MX records for a domain.
  use Net::DNS::Resolver;
  $res = new Net::DNS::Resolver;
  $query = $res->query("foo.com", "MX");
  foreach $mxhost ($query->answer) {
      print $mxhost->preference, " ", $mxhost->exchange, "\n";
  }

  # Print a domain's SOA record in zone file format.
  use Net::DNS::Resolver;
  $res = new Net::DNS::Resolver;
  $query = $res->query("foo.com", "SOA");
  ($query->answer)[0]->print;

=head1 BUGS

TCP transfers are not yet implemented.  Zone transfers won't be
possible until they are.

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS::Resolver>, L<Net::DNS::Packet>, L<Net::DNS::Header>,
L<Net::DNS::Question>, L<Net::DNS::RR>,
RFC 1035

=cut

use vars qw(
	$VERSION
	%typesbyname
	%typesbyval
	%classesbyname
	%classesbyval
	%opcodesbyname
	%opcodesbyval
	%rcodesbyname
	%rcodesbyval
);

use Net::DNS::Resolver;
use Net::DNS::Packet;
use Net::DNS::Header;
use Net::DNS::Question;
use Net::DNS::RR;

# $Id: DNS.pm,v 1.4 1997/02/03 05:58:37 mfuhr Exp $
$VERSION = "0.02";

%typesbyname= (
	"A"		=> 1,		# RFC 1035, Section 3.4.1
	"NS"		=> 2,		# RFC 1035, Section 3.3.11
	"MD"		=> 3,		# RFC 1035, Section 3.3.4
	"MF"		=> 4,		# RFC 1035, Section 3.3.5
	"CNAME"		=> 5,		# RFC 1035, Section 3.3.1
	"SOA"		=> 6,		# RFC 1035, Section 3.3.13
	"MB"		=> 7,		# RFC 1035, Section 3.3.3
	"MG"		=> 8,		# RFC 1035, Section 3.3.6
	"MR"		=> 9,		# RFC 1035, Section 3.3.8
	"NULL"		=> 10,		# RFC 1035, Section 3.3.10
	"WKS"		=> 11,		# RFC 1035, Section 3.4.2
	"PTR"		=> 12,		# RFC 1035, Section 3.3.12
	"HINFO"		=> 13,		# RFC 1035, Section 3.3.2
	"MINFO" 	=> 14,		# RFC 1035, Section 3.3.7
	"MX"		=> 15,		# RFC 1035, Section 3.3.9
	"TXT"		=> 16,		# RFC 1035, Section 3.3.14
	"RP"		=> 17,		# RFC 1183, Section 2.2
	"AFSDB"		=> 18,		# RFC 1183, Section 1
	"X25"		=> 19,		# RFC 1183, Section 3.1
	"ISDN"		=> 20,		# RFC 1183, Section 3.2
	"RT"		=> 21,		# RFC 1183, Section 3.3
	"NSAP"		=> 22,		# RFC 1706, Section 5
	"NSAP_PTR"	=> 23,
	"SIG"		=> 24,
	"KEY"		=> 25,
	"PX"		=> 26,		# RFC 1664, Section 4
	"GPOS"		=> 27,
	"AAAA"		=> 28,
	"LOC"		=> 29,
	"NXT"		=> 30,
	"EID"		=> 31,
	"NIMLOC"	=> 32,
	"SRV"		=> 33,		# RFC 2052
	"ATMA"		=> 34,
	"NAPTR"		=> 35,
	"UINFO"		=> 100,		# non-standard
	"UID"		=> 101,		# non-standard
	"GID"		=> 102,		# non-standard
	"UNSPEC"	=> 103,		# non-standard
	"IXFR"		=> 251,
	"AXFR"		=> 252,
	"MAILB"		=> 253,
	"MAILA"		=> 254,
	"ANY"		=> 255,
);
%typesbyval = map { ($typesbyname{$_} => $_) } keys %typesbyname;

%classesbyname = (
	"IN"		=> 1,
	"CH"		=> 3,
	"HS"		=> 4,
	"ANY"		=> 255,
);
%classesbyval = map { ($classesbyname{$_} => $_) } keys %classesbyname;

%opcodesbyname = (
	"QUERY"		=> 0,
	"IQUERY"	=> 1,
	"STATUS"	=> 2,
	"NS_NOTIFY_OP"	=> 4,
);
%opcodesbyval = map { ($opcodesbyname{$_} => $_) } keys %opcodesbyname;

%rcodesbyname = (
	"NOERROR"	=> 0,
	"FORMERR"	=> 1,
	"SERVFAIL"	=> 2,
	"NXDOMAIN"	=> 3,
	"NOTIMP"	=> 4,
	"REFUSED"	=> 5,
);
%rcodesbyval = map { ($rcodesbyname{$_} => $_) } keys %rcodesbyname;

sub PACKETSZ  { 512; }
sub HFIXEDSZ  {  12; }
sub QFIXEDSZ  {   4; }
sub RRFIXEDSZ {  10; }
sub INT32SZ   {   4; }
sub INT16SZ   {   2; }

1;
