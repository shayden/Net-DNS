package Net::DNS::RR;

use strict;
use vars qw($VERSION $AUTOLOAD);

use Carp;
use Net::DNS;

# $Id: RR.pm,v 1.9 1997/06/13 03:39:58 mfuhr Exp $
$VERSION = $Net::DNS::VERSION;

=head1 NAME

Net::DNS::RR - DNS Resource Record class

=head1 SYNOPSIS

C<use Net::DNS::RR>

=head1 DESCRIPTION

C<Net::DNS::RR> is the base class for DNS Resource Record (RR) objects.
See also the manual pages for each RR type.

=head1 METHODS

=cut

my %RR;

# Need to figure out a good way to autoload these.
use Net::DNS::RR::A;		$RR{"A"}	= 1;
use Net::DNS::RR::AAAA;		$RR{"AAAA"}	= 1;
use Net::DNS::RR::AFSDB;	$RR{"AFSDB"}	= 1;
use Net::DNS::RR::CNAME;	$RR{"CNAME"}	= 1;
use Net::DNS::RR::EID;		$RR{"EID"}	= 1;
use Net::DNS::RR::HINFO;	$RR{"HINFO"}	= 1;
use Net::DNS::RR::ISDN;		$RR{"ISDN"}	= 1;
use Net::DNS::RR::LOC;		$RR{"LOC"}	= 1;
use Net::DNS::RR::MB;		$RR{"MB"}	= 1;
use Net::DNS::RR::MG;		$RR{"MG"}	= 1;
use Net::DNS::RR::MINFO;	$RR{"MINFO"}	= 1;
use Net::DNS::RR::MR;		$RR{"MR"}	= 1;
use Net::DNS::RR::MX;		$RR{"MX"}	= 1;
use Net::DNS::RR::NAPTR;	$RR{"NAPTR"}	= 1;
use Net::DNS::RR::NIMLOC;	$RR{"NIMLOC"}	= 1;
use Net::DNS::RR::NS;		$RR{"NS"}	= 1;
use Net::DNS::RR::NSAP;		$RR{"NSAP"}	= 1;
use Net::DNS::RR::NULL;		$RR{"NULL"}	= 1;
use Net::DNS::RR::PTR;		$RR{"PTR"}	= 1;
use Net::DNS::RR::PX;		$RR{"PX"}	= 1;
use Net::DNS::RR::RP;		$RR{"RP"}	= 1;
use Net::DNS::RR::RT;		$RR{"RT"}	= 1;
use Net::DNS::RR::SOA;		$RR{"SOA"}	= 1;
use Net::DNS::RR::SRV;		$RR{"SRV"}	= 1;
use Net::DNS::RR::TXT;		$RR{"TXT"}	= 1;
use Net::DNS::RR::X25;		$RR{"X25"}	= 1;

=head2 new

    $rr = new Net::DNS::RR(
	Name    => "foo.bar.com",
	TTL     => 86400,
	Class   => "IN",
        Type    => "A",
	Address => "10.1.2.3",
    );

    $rr = new Net::DNS::RR(
	Name    => "foo.bar.com",
        Type    => "A",
    );

Returns an RR object of the appropriate type, or a C<Net::DNS::RR>
object if the type isn't implemented.  See the manual pages for
each RR type to see what fields the type requires.

The C<Name> and C<Type> fields are required; all others are optional.
If omitted, C<TTL> defaults to 0 and C<Class> defaults to IN.  Omitting
the optional fields is useful for creating the empty RDATA sections
required for certain dynamic update operations.

The fields are case-insensitive, but starting each with uppercase
is recommended.

=cut

sub new {
	my $class = shift;
	my $retval;
	my %self;

	if (@_ == 7 && ref $_[5]) {
		my ($name, $rrtype, $rrclass, $ttl,
		    $rdlength, $data, $offset) = @_;

		%self = (
			"name"		=> $name,
			"type"		=> $rrtype,
			"class"		=> $rrclass,
			"ttl"		=> $ttl,
			"rdlength"	=> $rdlength,
			"rdata"		=> substr($$data, $offset, $rdlength),
		);

		my $subclass = $class . "::" . $rrtype;

		if ($RR{$rrtype}) {
			$retval = new $subclass(\%self, $data, $offset);
		}
		else {
			$retval = bless \%self, $class;
		}
	}
	else {
		my %tempself = @_;
		my ($key, $val);

		while (($key, $val) = each %tempself) {
			$self{lc($key)} = $val;
		}

		Carp::confess("RR name not specified")
			unless exists $self{"name"};
		Carp::confess("RR type not specified")
			unless exists $self{"type"};

		$self{"ttl"}   = 0    unless exists $self{"ttl"};
		$self{"class"} = "IN" unless exists $self{"class"};

		$self{"rdlength"} = length $self{"rdata"}
			if exists $self{"rdata"};

		if ($RR{$self{"type"}}) {
			my $subclass = $class . "::" . $self{"type"};
			$retval = bless \%self, $subclass;
		}
		else {
			$retval = bless \%self, $class;
		}
	}

	return $retval;
}

#
# Some people have reported that Net::DNS dies because AUTOLOAD picks up
# calls to DESTROY.
#
sub DESTROY {}

=head2 print

    $rrobj->print;

Prints the record to the standard output.  Calls the
B<string> method to get the RR's string representation.

=cut

sub print {
	my $self = shift;
	print $self->string, "\n";
}

=head2 string

    print $rrobj->string, "\n";

Returns a string representation of the RR.  Calls the
B<rdatastr> method to get the RR-specific data.

=cut

sub string {
	my $self = shift;

	return $self->{"name"}  . ".\t" .
	       $self->{"ttl"}   . "\t"  .
	       $self->{"class"} . "\t"  .
	       $self->{"type"}  . "\t"  .
	       $self->rdatastr;
}

=head2 rdatastr

    $s = $rrobj->rdatastr;

Returns a string containing RR-specific data.  Subclasses will need
to implement this method.

=cut

sub rdatastr {
	my $self = shift;
	return exists $self->{"rdlength"}
	       ? "; rdlength = " . $self->{"rdlength"}
	       : "; no data";
}

=head2 name

    $name = $rrobj->name;

Returns the record's domain name.

=head2 type

    $type = $rrobj->type;

Returns the record's type.

=head2 class

    $class = $rrobj->class;

Returns the record's class.

=head2 ttl

    $ttl = $rrobj->ttl;

Returns the record's time-to-live (TTL).

=head2 rdlength

    $rdlength = $rrobj->rdlength;

Returns the length of the record's data section.

=head2 rdata

    $rdata = $rrobj->rdata

Returns the record's data section as binary data.

=cut

sub rdata {
	my $self = shift;
	my $retval = undef;

	if (@_ == 2) {
		my ($packet, $offset) = @_;
		$retval = $self->rr_rdata($packet, $offset);
	}
	elsif (exists $self->{"rdata"}) {
		$retval = $self->{"rdata"};
	}

	return $retval;
}

sub rr_rdata {
	my $self = shift;
	return exists $self->{"rdata"} ? $self->{"rdata"} : "";
}

#------------------------------------------------------------------------------
# sub data
#
# This method is called by Net::DNS::Packet->data to get the binary
# representation of an RR.
#------------------------------------------------------------------------------

sub data {
	my ($self, $packet, $offset) = @_;
	my $data;

	$data  = $packet->dn_comp($self->{"name"}, $offset);
	$data .= pack("n", $Net::DNS::typesbyname{uc($self->{"type"})});
	$data .= pack("n", $Net::DNS::classesbyname{uc($self->{"class"})});
	$data .= pack("N", $self->{"ttl"});

	$offset += length($data) + &Net::DNS::INT16SZ;	# allow for rdlength

	my $rdata = $self->rdata($packet, $offset);

	$data .= pack("n", length $rdata);
	$data .= $rdata;

	return $data;
}

sub AUTOLOAD {
	my $self = shift;
	my $name = $AUTOLOAD;
	$name =~ s/.*://;

	if (@_) {
		$self->{$name} = shift;
	} elsif (!exists $self->{$name}) {
		Carp::confess "\nERROR: no such method \"$name\" for the " .
			      "following RR.\nPlease check your RR types " .
			      "and call appropriate methods.\n\n  " .
			      $self->string . "\n\nDied";
	}

	return $self->{$name};
}

=head1 BUGS

This version of C<Net::DNS::RR> does no sanity checking on user-created
RR objects.

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Resolver>, L<Net::DNS::Packet>,
L<Net::DNS::Update>, L<Net::DNS::Header>, L<Net::DNS::Question>,
RFC 1035 Section 4.1.3

=cut

1;
