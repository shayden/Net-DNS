package Net::DNS::Header;

use strict;
use vars qw($VERSION $AUTOLOAD);

use Net::DNS;

# $Id: Header.pm,v 1.2 1997/02/02 08:32:08 mfuhr Exp $
$VERSION = $Net::DNS::VERSION;

=head1 NAME

Net::DNS::Header - DNS packet header class

=head1 SYNOPSIS

C<use Net::DNS::Header;>

=head1 DESCRIPTION

A C<Net::DNS::Header> object represents the header portion of a DNS
packet.

=head1 METHODS

=head2 new

    $header = new Net::DNS::Header;
    $header = new Net::DNS::Header(\$data);

Without an argument, C<new> creates a header object appropriate
for making a DNS query.

If C<new> is passed a reference to a scalar containing DNS packet
data, it creates a header object from that data.

=cut

sub new {
	my $class = shift;
	my %self;

	if (@_) {
		my $data = shift;
		my @a = unpack("n C2 n4", $$data);
		%self = (
			"id"		=> $a[0],
			"qr"		=> ($a[1] >> 7) & 0x1,
			"opcode"	=> ($a[1] >> 3) & 0xf,
			"aa"		=> ($a[1] >> 2) & 0x1,
			"tc"		=> ($a[1] >> 1) & 0x1,
			"rd"		=> $a[1] & 0x1,
			"ra"		=> ($a[2] >> 7) & 0x1,
			"rcode"		=> $a[2] & 0xf,
			"qdcount"	=> $a[3],
			"ancount"	=> $a[4],
			"nscount"	=> $a[5],
			"arcount"	=> $a[6],
		);
	}
	else {
		%self = (
			"id"		=> Net::DNS::Resolver::nextid(),
			"qr"		=> 0,
			"opcode"	=> 0,
			"aa"		=> 0,
			"tc"		=> 0,
			"rd"		=> 1,
			"ra"		=> 0,
			"rcode"		=> 0,
			"qdcount"	=> 1,
			"ancount"	=> 0,
			"nscount"	=> 0,
			"arcount"	=> 0,
		);
	}

	$self{"opcode"} = $Net::DNS::opcodesbyval{$self{"opcode"}}
		if exists $Net::DNS::opcodesbyval{$self{"opcode"}};
	$self{"rcode"} = $Net::DNS::rcodesbyval{$self{"rcode"}}
		if exists $Net::DNS::rcodesbyval{$self{"rcode"}};

	return bless \%self, $class;
}

=head2 print

    $header->print;

Dumps the header data to the standard output.

=cut

sub print {
	my $self = shift;

	print ";; id = $self->{id}\n";

	print ";; qr = $self->{qr}    ",
	      "opcode = $self->{opcode}    ",
	      "aa = $self->{aa}    ",
	      "tc = $self->{tc}    ",
	      "rd = $self->{rd}\n";

	print ";; ra = $self->{ra}    ",
	      "rcode  = $self->{rcode}\n";
}

=head2 id

    print "query id = ", $header->id, "\n";

Returns the query identification number.

=head2 qr

    print "query response flag = ", $header->qr, "\n";

Returns the query response flag.

=head2 opcode

    print "query opcode = ", $header->opcode, "\n";

Returns the query opcode (the purpose of the query).

=head2 aa

    print "answer is ", $header->aa ? "" : "non-", "authoritative\n";

Returns true if this is an authoritative answer.

=head2 tc

    print "packet is ", $header->tc ? "" : "not ", "truncated\n";

Returns true if this packet is truncated.

=head2 rd

    print "recursion was ", $header->rd ? "" : "not ", "desired\n";

Returns true if recursion was desired.

=head2 ra

    print "recursion is ", $header->ra ? "" : "not ", "available\n";

Returns true if recursion is available.

=head2 rcode

    print "query response code = ", $header->rcode, "\n";

The query response code, i.e., the status of the query.

=head2 qdcount

    print "# of question records: ", $header->qdcount, "\n";

Returns the number of records in the question section of the packet.

=head2 ancount

    print "# of answer records: ", $header->ancount, "\n";

Returns the number of records in the answer section of the packet.

=head2 nscount

    print "# of authority records: ", $header->nscount, "\n";

Returns the number of records in the authority section of the packet.

=head2 arcount

    print "# of additional records: ", $header->arcount, "\n";

Returns the number of records in the additional section of the packet.

=cut

sub AUTOLOAD {
	my $self = shift;
	my $name = $AUTOLOAD;
	$name =~ s/.*://;

	Carp::confess "$name: no such method"
		unless exists $self->{$name};

	$self->{$name} = shift if @_;
	return $self->{$name};
}

=head2 data

    $hdata = $header->data;

Returns the header data in binary format, appropriate for use in a
DNS query packet.

=cut

sub data {
	my $self = shift;

	my $opcode = $Net::DNS::opcodesbyname{$self->{"opcode"}};
	my $rcode  = $Net::DNS::rcodesbyname{$self->{"rcode"}};

	my $byte2 = ($self->{"qr"} << 7)
	          | ($opcode << 3)
	          | ($self->{"aa"} << 2)
	          | ($self->{"tc"} << 1)
	          | $self->{"rd"};

	my $byte3 = ($self->{"ra"} << 7)
	          | $rcode;

	return pack("n C2 n4", $self->{"id"},
			       $byte2,
			       $byte3,
			       $self->{"qdcount"},
			       $self->{"ancount"},
			       $self->{"nscount"},
			       $self->{"arcount"});
}

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Resolver>, L<Net::DNS::Packet>,
L<Net::DNS::Question>, L<Net::DNS::RR>,
RFC 1035 Section 4.1.1

=cut

1;
