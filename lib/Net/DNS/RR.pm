package Net::DNS::RR;

use strict;
use vars qw($VERSION $AUTOLOAD);

use Net::DNS;

# $Id: RR.pm,v 1.8 1997/05/29 17:38:03 mfuhr Exp $
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
use Net::DNS::RR::AFSDB;	$RR{"AFSDB"}	= 1;
use Net::DNS::RR::CNAME;	$RR{"CNAME"}	= 1;
use Net::DNS::RR::HINFO;	$RR{"HINFO"}	= 1;
use Net::DNS::RR::ISDN;		$RR{"ISDN"}	= 1;
use Net::DNS::RR::LOC;		$RR{"LOC"}	= 1;
use Net::DNS::RR::MG;		$RR{"MG"}	= 1;
use Net::DNS::RR::MINFO;	$RR{"MINFO"}	= 1;
use Net::DNS::RR::MR;		$RR{"MR"}	= 1;
use Net::DNS::RR::MX;		$RR{"MX"}	= 1;
use Net::DNS::RR::NAPTR;	$RR{"NAPTR"}	= 1;
use Net::DNS::RR::NS;		$RR{"NS"}	= 1;
use Net::DNS::RR::PTR;		$RR{"PTR"}	= 1;
use Net::DNS::RR::RP;		$RR{"RP"}	= 1;
use Net::DNS::RR::RT;		$RR{"RT"}	= 1;
use Net::DNS::RR::SOA;		$RR{"SOA"}	= 1;
use Net::DNS::RR::SRV;		$RR{"SRV"}	= 1;
use Net::DNS::RR::TXT;		$RR{"TXT"}	= 1;
use Net::DNS::RR::X25;		$RR{"X25"}	= 1;

sub new {
	my $class = shift;
	my ($name, $rrtype, $rrclass, $ttl, $rdlength, $data, $offset) = @_;
	my $retval;

	my %self = (
		"name"		=> $name,
		"type"		=> $rrtype,
		"class"		=> $rrclass,
		"ttl"		=> $ttl,
		"rdlength"	=> $rdlength,
	);

	my $subclass = $class . "::" . $rrtype;

	if ($RR{$rrtype}) {
		$retval = new $subclass(\%self, $data, $offset);
	}
	else {
		$retval = bless \%self, $class;
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
	return "; rdlength = " . $self->{"rdlength"};
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

=cut

sub AUTOLOAD {
	my $self = shift;
	my $name = $AUTOLOAD;
	$name =~ s/.*://;

	unless (exists $self->{$name}) {
		Carp::confess "ERROR: no such method \"$name\" for the " .
			      "following RR.\nPlease check your RR types " .
			      "and call appropriate methods.\n\n" .
			      $self->string . "\n\nDied";
	}

	return $self->{$name};
}

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Resolver>, L<Net::DNS::Packet>,
L<Net::DNS::Header>, L<Net::DNS::Question>, RFC 1035 Section 4.1.3

=cut

1;
