package Net::DNS;
# $Id: DNS.pm,v 1.20 2001/02/07 05:12:43 mfuhr Exp mfuhr $

require 5.6.0;

use strict;
use vars qw(
	$VERSION
	@ISA
	@EXPORT
	%typesbyname
	%typesbyval
	%classesbyname
	%classesbyval
	%opcodesbyname
	%opcodesbyval
	%rcodesbyname
	%rcodesbyval
);

$VERSION = "0.19";

use Net::DNS::Resolver;
use Net::DNS::Packet;
use Net::DNS::Update;
use Net::DNS::Header;
use Net::DNS::Question;
use Net::DNS::RR;
use Net::DNS::Nameserver;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(mx yxrrset nxrrset yxdomain nxdomain rr_add rr_del);

%typesbyname= (
	"A"		=> 1,		# RFC 1035, Section 3.4.1
	"NS"		=> 2,		# RFC 1035, Section 3.3.11
	"MD"		=> 3,		# RFC 1035, Section 3.3.4 (obsolete)
	"MF"		=> 4,		# RFC 1035, Section 3.3.5 (obsolete)
	"CNAME"		=> 5,		# RFC 1035, Section 3.3.1
	"SOA"		=> 6,		# RFC 1035, Section 3.3.13
	"MB"		=> 7,		# RFC 1035, Section 3.3.3
	"MG"		=> 8,		# RFC 1035, Section 3.3.6
	"MR"		=> 9,		# RFC 1035, Section 3.3.8
	"NULL"		=> 10,		# RFC 1035, Section 3.3.10
	"WKS"		=> 11,		# RFC 1035, Section 3.4.2 (deprecated)
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
	"NSAP_PTR"	=> 23,		# RFC 1348 (obsolete)
	"SIG"		=> 24,		# RFC 2535
	"KEY"		=> 25,		# RFC 2535
	"PX"		=> 26,		# RFC 2163
	"GPOS"		=> 27,		# RFC 1712 (obsolete)
	"AAAA"		=> 28,		# RFC 1886, Section 2.1
	"LOC"		=> 29,		# RFC 1876
	"NXT"		=> 30,		# RFC 2535
	"EID"		=> 31,		# draft-ietf-nimrod-dns-xx.txt
	"NIMLOC"	=> 32,		# draft-ietf-nimrod-dns-xx.txt
	"SRV"		=> 33,		# RFC 2782
	"ATMA"		=> 34,		# [Dobrowski]
	"NAPTR"		=> 35,		# RFC 2168, 2915
	"KX"		=> 36,		# RFC 2230
	"CERT"		=> 37,		# RFC 2358
	"A6"		=> 38,		# RFC 2874
	"DNAME"		=> 39,		# RFC 2672
	"SINK"		=> 40,		# [Eastlake]
	"OPT"		=> 41,		# RFC 2671
	"UINFO"		=> 100,		# [IANA-Reserved]
	"UID"		=> 101,		# [IANA-Reserved]
	"GID"		=> 102,		# [IANA-Reserved]
	"UNSPEC"	=> 103,		# [IANA-Reserved]
	"TKEY"		=> 249,		# RFC 2930
	"TSIG"		=> 250,		# RFC 2845
	"IXFR"		=> 251,		# RFC 1995
	"AXFR"		=> 252,		# RFC 1035
	"MAILB"		=> 253,		# RFC 1035 (MB, MG, MR)
	"MAILA"		=> 254,		# RFC 1035 (obsolete - see MX)
	"ANY"		=> 255,		# RFC 1035
);
%typesbyval = map { ($typesbyname{$_} => $_) } keys %typesbyname;

%classesbyname = (
	"IN"		=> 1,		# RFC 1035
	"CH"		=> 3,		# RFC 1035
	"HS"		=> 4,		# RFC 1035
	"NONE"		=> 254,		# RFC 2136
	"ANY"		=> 255,		# RFC 1035
);
%classesbyval = map { ($classesbyname{$_} => $_) } keys %classesbyname;
$classesbyname{"CHAOS"} = $classesbyname{"CH"};

%opcodesbyname = (
	"QUERY"		=> 0,		# RFC 1035
	"IQUERY"	=> 1,		# RFC 1035
	"STATUS"	=> 2,		# RFC 1035
	"NOTIFY"	=> 4,		# RFC 1996
	"UPDATE"	=> 5,		# RFC 2136
);
%opcodesbyval = map { ($opcodesbyname{$_} => $_) } keys %opcodesbyname;
$opcodesbyname{"NS_NOTIFY_OP"} = $opcodesbyname{"NOTIFY"};

%rcodesbyname = (
	"NOERROR"	=> 0,		# RFC 1035
	"FORMERR"	=> 1,		# RFC 1035
	"SERVFAIL"	=> 2,		# RFC 1035
	"NXDOMAIN"	=> 3,		# RFC 1035
	"NOTIMP"	=> 4,		# RFC 1035
	"REFUSED"	=> 5,		# RFC 1035
	"YXDOMAIN"	=> 6,		# RFC 2136
	"YXRRSET"	=> 7,		# RFC 2136
	"NXRRSET"	=> 8,		# RFC 2136
	"NOTAUTH"	=> 9,		# RFC 2136
	"NOTZONE"	=> 10,		# RFC 2136
	"BADSIG"	=> 16,		# RFC 2845 (also BADVERS, RFC 2671)
	"BADKEY"	=> 17,		# RFC 2845
	"BADTIME"	=> 18,		# RFC 2845
	"BADMODE"	=> 19,		# RFC 2930
	"BADNAME"	=> 20,		# RFC 2930
	"BADALG"	=> 21,		# RFC 2930
);
%rcodesbyval = map { ($rcodesbyname{$_} => $_) } keys %rcodesbyname;
$rcodesbyname{"BADVERS"} = 16;

sub version	{ $VERSION; }
sub PACKETSZ	{ 512; }
sub HFIXEDSZ	{  12; }
sub QFIXEDSZ	{   4; }
sub RRFIXEDSZ	{  10; }
sub INT32SZ	{   4; }
sub INT16SZ	{   2; }

sub mx {
	my ($res, $name, $class);
	my ($ans, @mxlist);

	$res = ref $_[0] ? shift : Net::DNS::Resolver->new;
	($name, $class) = @_;
	$class = "IN" unless defined $class;

	$ans = $res->query($name, "MX", $class);

	if (defined $ans) {
		@mxlist = grep { $_->type eq "MX" } $ans->answer;
		@mxlist = sort { $a->preference <=> $b->preference } @mxlist;
	}

	return @mxlist;
}

sub yxrrset {
	my $string = shift;
	return Net::DNS::RR->new_from_string($string, "yxrrset");
}

sub nxrrset {
	my $string = shift;
	return Net::DNS::RR->new_from_string($string, "nxrrset");
}

sub yxdomain {
	my $string = shift;
	return Net::DNS::RR->new_from_string($string, "yxdomain");
}

sub nxdomain {
	my $string = shift;
	return Net::DNS::RR->new_from_string($string, "nxdomain");
}

sub rr_add {
	my $string = shift;
	return Net::DNS::RR->new_from_string($string, "rr_add");
}

sub rr_del {
	my $string = shift;
	return Net::DNS::RR->new_from_string($string, "rr_del");
}

1;
__END__

=head1 NAME

Net::DNS - Perl interface to the DNS resolver

=head1 SYNOPSIS

C<use Net::DNS;>

=head1 DESCRIPTION

Net::DNS is a collection of Perl modules that acts as a Domain Name
System (DNS) resolver.  It allows the programmer to perform DNS
queries that are beyond the capabilities of C<gethostbyname> and
C<gethostbyaddr>.

The programmer should be familiar with the format of a DNS packet
and its various sections.  See RFC 1035 or I<DNS and BIND> (Albitz
& Liu) for details.

Programmers interested in using Net::DNS to perform dynamic updates
should be familiar with RFC 2136.  Those interested in performing
signed (TSIG) transactions should be familiar with RFC 2845.

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

The C<Net::DNS::Update> package is a front-end to C<Net::DNS::Packet>
for creating packet objects to be used in dynamic updates.

=head2 Header Objects

C<Net::DNS::Header> objects represent the header section of a DNS packet.

=head2 Question Objects

C<Net::DNS::Question> objects represent the question section of a DNS packet.

=head2 RR Objects

C<Net::DNS::RR> is the base class for DNS resource record (RR) objects in
the answer, authority, and additional sections of a DNS packet.

Don't assume that RR objects will be of the type you requested -- always
check an RR object's type before calling any of its methods.

=head1 METHODS

See the manual pages listed above for other class-specific methods.

=head2 version

    print Net::DNS->version, "\n";

Returns the version of Net::DNS.

=head2 mx

    # Use a default resolver -- can't get an error string this way.
    use Net::DNS;
    @mx = mx("example.com");

    # Use your own resolver object.
    use Net::DNS;
    $res = Net::DNS::Resolver->new;
    @mx = mx($res, "example.com");

Returns a list of C<Net::DNS::RR::MX> objects representing the MX
records for the specified name; the list will be sorted by preference.
Returns an empty list if the query failed or no MX records were
found.

This method does not look up A records -- it only performs MX queries.

See L</EXAMPLES> for a more complete example.

=head2 yxrrset

Use this method to add an "RRset exists" prerequisite to a dynamic
update packet.  There are two forms, value-independent and
value-dependent:

    # RRset exists (value-independent)
    $packet->push("pre", yxrrset("foo.example.com A"));

Meaning:  At least one RR with the specified name and type must
exist.

    # RRset exists (value-dependent)
    $packet->push("pre", yxrrset("foo.example.com A 10.1.2.3"));

Meaning:  At least one RR with the specified name and type must
exist and must have matching data.

Returns a C<Net::DNS::RR> object or C<undef> if the object couldn't
be created.

=head2 nxrrset

Use this method to add an "RRset does not exist" prerequisite to
a dynamic update packet.

    $packet->push("pre", nxrrset("foo.example.com A"));

Meaning:  No RRs with the specified name and type can exist.

Returns a C<Net::DNS::RR> object or C<undef> if the object couldn't
be created.

=head2 yxdomain

Use this method to add a "name is in use" prerequisite to a dynamic
update packet.

    $packet->push("pre", yxdomain("foo.example.com"));

Meaning:  At least one RR with the specified name must exist.

Returns a C<Net::DNS::RR> object or C<undef> if the object couldn't
be created.

=head2 nxdomain

Use this method to add a "name is not in use" prerequisite to a
dynamic update packet.

    $packet->push("pre", nxdomain("foo.example.com"));

Meaning:  No RR with the specified name can exist.

Returns a C<Net::DNS::RR> object or C<undef> if the object couldn't
be created.

=head2 rr_add

Use this method to add RRs to a zone.

    $packet->push("update", rr_add("foo.example.com A 10.1.2.3"));

Meaning:  Add this RR to the zone.

RR objects created by this method should be added to the "update"
section of a dynamic update packet.  The TTL defaults to 86400
seconds (24 hours) if not specified.

Returns a C<Net::DNS::RR> object or C<undef> if the object couldn't
be created.

=head2 rr_del

Use this method to delete RRs from a zone.  There are three forms:
delete an RRset, delete all RRsets, and delete an RR.

    # Delete an RRset.
    $packet->push("update", rr_del("foo.example.com A"));

Meaning:  Delete all RRs having the specified name and type.

    # Delete all RRsets.
    $packet->push("update", rr_del("foo.example.com"));

Meaning:  Delete all RRs having the specified name.

    # Delete an RR.
    $packet->push("update", rr_del("foo.example.com A 10.1.2.3"));

Meaning:  Delete all RRs having the specified name, type, and data.

RR objects created by this method should be added to the "update"
section of a dynamic update packet.

Returns a C<Net::DNS::RR> object or C<undef> if the object couldn't
be created.

=head1 EXAMPLES

The following examples show how to use the C<Net::DNS> modules.
See the other manual pages and the demo scripts included with the
source code for additional examples.

Many of the examples are intentionally simple and don't do things
like follow CNAME records.  Such code is left as an exercise for
the reader.

See the C<Net::DNS::Update> manual page for examples of performing
dynamic updates.  RFC 2136 describes dynamic updates.

See the C<Net::DNS::Packet> and C<Net::DNS::Update> manual pages
for examples of performing signed queries and updates.  RFC 2845
describes signing DNS transactions with TSIG records.

=head2 Look up a host's address from its name.

  #!/usr/bin/perl -w
  use Net::DNS;
  $res = Net::DNS::Resolver->new;
  $query = $res->search("foo.example.com");
  if ($query) {
      foreach $rr ($query->answer) {
          next unless $rr->type eq "A";
          print $rr->address, "\n";
      }
  }
  else {
      print "query failed: ", $res->errorstring, "\n";
  }

=head2 Look up a host's name from its address.

  #!/usr/bin/perl -w
  use Net::DNS;
  $res = Net::DNS::Resolver->new;
  $query = $res->query("10.1.2.3");
  if ($query) {
      foreach $rr ($query->answer) {
	  next unless $rr->type eq "PTR";
	  print $rr->ptrdname, "\n";
      }
  }
  else {
      print "query failed: ", $res->errorstring, "\n";
  }

=head2 Find the nameservers for a domain.

  #!/usr/bin/perl -w
  use Net::DNS;
  $res = Net::DNS::Resolver->new;
  $query = $res->query("example.com", "NS");
  if ($query) {
      foreach $rr ($query->answer) {
          next unless $rr->type eq "NS";
          print $rr->nsdname, "\n";
      }
  }
  else {
      print "query failed: ", $res->errorstring, "\n";
  }

=head2 Find the MX records for a domain.

  #!/usr/bin/perl -w
  use Net::DNS;
  $name = "example.com";
  $res = Net::DNS::Resolver->new;
  @mx = mx($res, $name);
  if (@mx) {
      foreach $rr (@mx) {
          print $rr->preference, " ", $rr->exchange, "\n";
      }
  }
  else {
      print "can't find MX records for $name: ", $res->errorstring, "\n";
  }


=head2 Print a domain's SOA record in zone file format.

  #!/usr/bin/perl -w
  use Net::DNS;
  $res = Net::DNS::Resolver->new;
  $query = $res->query("example.com", "SOA");
  if ($query) {
      ($query->answer)[0]->print;
  }
  else {
      print "query failed: ", $res->errorstring, "\n";
  }

=head2 Perform a zone transfer and print all the records.

  #!/usr/bin/perl -w
  use Net::DNS;
  $res = Net::DNS::Resolver->new;
  $res->nameservers("ns.example.com");
  @zone = $res->axfr("example.com");
  foreach $rr (@zone) {
      $rr->print;
  }

=head2 Perform a background query and do some other work while waiting for the answer.

  #!/usr/bin/perl -w
  use Net::DNS;
  $res = Net::DNS::Resolver->new;
  $socket = $res->bgsend("foo.example.com");
  until ($res->bgisready($socket)) {
      # do some work here while waiting for the answer
      # ...and some more here
  }
  $packet = $res->bgread($socket);
  $packet->print;


=head2 Send a background query and use select to determine when the answer has arrived.

  #!/usr/bin/perl -w
  use Net::DNS;
  use IO::Select;
  $timeout = 5;
  $res = Net::DNS::Resolver->new;
  $bgsock = $res->bgsend("foo.example.com");
  $sel = IO::Select($bgsock)->new;
  # Add more sockets to $sel if desired.
  @ready = $sel->can_read($timeout);
  if (@ready) {
      foreach $sock (@ready) {
          if ($sock == $bgsock) {
              $packet = $res->bgread($bgsock);
              $packet->print;
              $bgsock = undef;
          }
	  # Check for the other sockets.
	  $sel->remove($sock);
	  $sock = undef;
      }
  }
  else {
      print "timed out after $timeout seconds\n";
  }

=head1 BUGS

C<Net::DNS> is slow.  Real slow.

C<Net::DNS> is crippled on Microsoft systems because Win32 Perl has
only a limited socket implementation.  UDP queries seem to be
problematic so TCP is the defualt.  TCP timeouts may not work.

On some systems, TCP queries result in the error "Resource temporarily
unavailable."  Setting $res->tcp_timeout(undef) seems to work around
this problem.

For other known issues, please see the TODO file included with the
source distribution.

=head1 COPYRIGHT

Copyright (c) 1997-2000 Michael Fuhr.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=head1 AUTHOR INFORMATION

Michael Fuhr <mike@fuhr.org>
http://www.fuhr.org/~mfuhr/perldns/

=head1 SEE ALSO
 
L<perl(1)>, L<Net::DNS::Resolver>, L<Net::DNS::Packet>, L<Net::DNS::Update>,
L<Net::DNS::Header>, L<Net::DNS::Question>, L<Net::DNS::RR>, RFC 1035,
RFC 2136, RFC 2845, I<DNS and BIND> by Paul Albitz & Cricket Liu

=cut
