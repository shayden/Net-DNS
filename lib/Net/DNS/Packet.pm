package Net::DNS::Packet;

use strict;
use vars qw($VERSION $AUTOLOAD);

use Carp;
use Net::DNS;
use Net::DNS::Question;
use Net::DNS::RR;

# $Id: Packet.pm,v 1.3 1997/03/28 01:22:15 mfuhr Exp $
$VERSION = $Net::DNS::VERSION;

=head1 NAME

Net::DNS::Packet - DNS packet object class

=head1 SYNOPSIS

C<use Net::DNS::Packet;>

=head1 DESCRIPTION

A C<Net::DNS::Packet> object represents a DNS packet.

=head1 METHODS

=head2 new

    $packet = new Net::DNS::Packet(\$data);
    $packet = new Net::DNS::Packet("foo.com", "MX", "IN");

If passed a reference to a scalar containing DNS packet data,
C<new> creates a packet object from that data.

If passed a domain, type, and class, C<new> creates a packet
object appropriate for making a DNS query for the requested
information.

=cut

sub new {
	my $class = shift;
	my %self;

	if (@_ == 1) {
		my $data = shift;
		$self{"header"} = new Net::DNS::Header($data);

		my $offset = &Net::DNS::HFIXEDSZ;

		$self{"question"} = [];
		foreach (1 .. $self{"header"}->qdcount) {
			my $qobj;
			($qobj, $offset) = parse_question($data, $offset);
			push(@{$self{"question"}}, $qobj);
		}
			
		$self{"answer"} = [];
		foreach (1 .. $self{"header"}->ancount) {
			my $rrobj;
			($rrobj, $offset) = parse_rr($data, $offset);
			push(@{$self{"answer"}}, $rrobj);
		}

		$self{"authority"} = [];
		foreach (1 .. $self{"header"}->nscount) {
			my $rrobj;
			($rrobj, $offset) = parse_rr($data, $offset);
			push(@{$self{"authority"}}, $rrobj);
		}

		$self{"additional"} = [];
		foreach (1 .. $self{"header"}->arcount) {
			my $rrobj;
			($rrobj, $offset) = parse_rr($data, $offset);
			push(@{$self{"additional"}}, $rrobj);
		}
	}
	elsif (@_ == 3) {
		my ($qname, $qtype, $qclass) = @_;
		$self{"header"} = new Net::DNS::Header;
		$self{"header"}->qdcount(1);
		$self{"question"} = [ new Net::DNS::Question($qname,
							     $qtype,
							     $qclass) ];
		$self{"answer"} = [];
		$self{"authority"} = [];
		$self{"additional"} = [];
	}
	else {
		Carp::confess("wrong number of arguments");
	}

	return bless \%self, $class;
}

=head2 data

    $data = $packet->data;

Returns the packet data in binary format, suitable for sending to
a nameserver.

=cut

sub data {
	my $self = shift;
	my $data = "";
	my $question;

	$data .= $self->{"header"}->data;
	foreach $question (@{$self->{"question"}}) {
		$data .= $question->data;
	}

	return $data;
}

=head2 header

    $header = $packet->header;

Returns a C<Net::DNS::Header> object representing the header section
of the packet.

=cut

sub header {
	my $self = shift;
	return $self->{"header"};
}

=head2 question, zone

    @question = $packet->question;

Returns a list of C<Net::DNS::Question> objects representing the
question section of the packet.

In dynamic update packets, this section is known as C<zone> and
specifies the zone to be updated.

=cut

sub question {
	my $self = shift;
	return @{$self->{"question"}};
}

sub zone {
	my $self = shift;
	$self->question(@_);
}

=head2 answer, pre, prerequisite

    @answer = $packet->answer;

Returns a list of C<Net::DNS::RR> objects representing the answer
section of the packet.

In dynamic update packets, this section is known as C<pre> or
C<prerequisite> and specifies the RRs or RRsets which must (not)
preexist.

=cut

sub answer {
	my $self = shift;
	return @{$self->{"answer"}};
}

sub pre {
	my $self = shift;
	$self->answer(@_);
}

sub prerequisite {
	my $self = shift;
	$self->answer(@_);
}

=head2 authority, update

    @authority = $packet->authority;

Returns a list of C<Net::DNS::RR> objects representing the authority
section of the packet.

In dynamic update packets, this section is known as C<update> and
specifies the RRs or RRsets to be added or delted.

=cut

sub authority {
	my $self = shift;
	return @{$self->{"authority"}};
}

sub update {
	my $self = shift;
	$self->authority(@_);
}

=head2 additional

    @additional = $packet->additional;

Returns a list of C<Net::DNS::RR> objects representing the additional
section of the packet.

=cut

sub additional {
	my $self = shift;
	return @{$self->{"additional"}};
}

=head2 print

    $packet->print;

Prints the packet data on the standard output in an ASCII format
similar to that used in DNS zone files.

=cut

sub print {
	my $self = shift;
	my ($qr, $rr, $section);

	print ";; HEADER SECTION\n";
	$self->header->print;

	print "\n";
	$section = ($self->header->opcode eq "UPDATE") ? "ZONE" : "QUESTION";
	print ";; $section SECTION (", $self->header->qdcount, " record",
	      $self->header->qdcount == 1 ? "" : "s", ")\n";
	foreach $qr ($self->question) {
		print ";; ";
		$qr->print;
	}

	print "\n";
	$section = ($self->header->opcode eq "UPDATE") ? "PREREQUISITE" : "ANSWER";
	print ";; $section SECTION (", $self->header->ancount, " record",
	      $self->header->ancount == 1 ? "" : "s", ")\n";
	foreach $rr ($self->answer) {
		$rr->print;
	}

	print "\n";
	$section = ($self->header->opcode eq "UPDATE") ? "UPDATE" : "AUTHORITY";
	print ";; $section SECTION (", $self->header->nscount, " record",
	      $self->header->nscount == 1 ? "" : "s", ")\n";
	foreach $rr ($self->authority) {
		$rr->print;
	}

	print "\n";
	print ";; ADDITIONAL SECTION (", $self->header->arcount, " record",
	      $self->header->arcount == 1 ? "" : "s", ")\n";
	foreach $rr ($self->additional) {
		$rr->print;
	}
}

=head2 dn_expand

    ($name, $nextoffset) = dn_expand(\$data, $offset);

Expands the domain name stored at a particular location in a
DNS packet.  The first argument is a reference to a
scalar containing the packet data.  The second argument is
the offset within the packet where the (possibly compressed)
domain name is stored.

Returns the domain name and the offset of the next location
in the packet.

=cut

sub dn_expand {
	my ($packet, $offset) = @_;
	my $name = "";
	my $len;

	while (1) {
		$len = unpack("\@$offset C", $$packet);
		if ($len == 0) {
			$offset++;
			last;
		}
		elsif (($len & 0xc0) == 0xc0) {
			my $ptr = unpack("\@$offset n", $$packet);
			$ptr &= 0x3fff;
			my($name2) = dn_expand($packet, $ptr);
			$name .= $name2;
			$offset += &Net::DNS::INT16SZ;
			last;
		}
		else {
			$offset++;
			my $elem = unpack("\@$offset a$len", $$packet);
			$name .= "$elem.";
			$offset += $len;
		}
	}
	$name =~ s/\.$//;
	return ($name, $offset);
}

#------------------------------------------------------------------------------
# parse_question
#
#     ($queryobj, $newoffset) = parse_question(\$data, $offset);
#
# Parses a question section record contained at a particular location within
# a DNS packet.  The first argument is a reference to the packet data.  The
# second argument is the offset within the packet where the question record
# begins.
#
# Returns a Net::DNS::Question object and the offset of the next location
# in the packet.
#------------------------------------------------------------------------------

sub parse_question {
	my ($data, $offset) = @_;
	my $qname;
	($qname, $offset) = dn_expand($data, $offset);
	my ($qtype, $qclass) = unpack("\@$offset n2", $$data);
	$offset += 2 * &Net::DNS::INT16SZ;
	$qtype = $Net::DNS::typesbyval{$qtype};
	$qclass = $Net::DNS::classesbyval{$qclass};
	return (new Net::DNS::Question($qname, $qtype, $qclass), $offset);
}

#------------------------------------------------------------------------------
# parse_rr
#
#    ($rrobj, $newoffset) = parse_rr(\$data, $offset);
#
# Parses a DNS resource record (RR) contained at a particular location
# within a DNS packet.  The first argument is a reference to a scalar
# containing the packet data.  The second argument is the offset within
# the data where the RR is located.
#
# Returns a Net::DNS::RR object and the offset of the next location
# in the packet.
#------------------------------------------------------------------------------

sub parse_rr {
	my ($data, $offset) = @_;
	my $name;

	($name, $offset) = dn_expand($data, $offset);

	my ($type, $class, $ttl, $rdlength) = unpack("\@$offset n2 N n", $$data);
	$type = $Net::DNS::typesbyval{$type};
	$class = $Net::DNS::classesbyval{$class};

	$offset += &Net::DNS::RRFIXEDSZ;

	my $rrobj = new Net::DNS::RR($name,
				     $type,
				     $class,
				     $ttl,
				     $rdlength, 
				     $data,
				     $offset);

	$offset += $rdlength;
	return ($rrobj, $offset);
}

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Resolver>, L<Net::DNS::Header>,
L<Net::DNS::Question>, L<Net::DNS::RR>,
RFC 1035 Section 4.1

=cut

1;
