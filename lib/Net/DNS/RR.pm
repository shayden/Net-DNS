package Net::DNS::RR;

use strict;
use vars qw($VERSION $AUTOLOAD);

use Net::DNS;

# $Id: RR.pm,v 1.3 1997/02/02 08:32:59 mfuhr Exp $
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

# Need to figure out a good way to autoload these.
use Net::DNS::RR::A;
use Net::DNS::RR::AFSDB;
use Net::DNS::RR::CNAME;
use Net::DNS::RR::HINFO;
use Net::DNS::RR::ISDN;
use Net::DNS::RR::MG;
use Net::DNS::RR::MINFO;
use Net::DNS::RR::MR;
use Net::DNS::RR::MX;
use Net::DNS::RR::NS;
use Net::DNS::RR::PTR;
use Net::DNS::RR::RP;
use Net::DNS::RR::RT;
use Net::DNS::RR::SOA;
use Net::DNS::RR::SRV;
use Net::DNS::RR::TXT;
use Net::DNS::RR::X25;

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
	eval "\$retval = new $subclass(\\\%self, \$data, \$offset)";
	if ($@) {
		$retval = bless \%self, $class;
	}

	return $retval;
}

=head2 print

    $rrobj->print;

Prints the record to the standard output.  Calls the
B<rdatastr> method to get the RR-specific data.

=cut

sub print {
	my $self = shift;
	print $self->{"name"}, ".\t",
	      $self->{"ttl"}, "\t",
	      $self->{"class"}, "\t",
	      $self->{"type"}, "\t",
	      $self->rdatastr,
	      "\n";
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
	Carp::confess "$name: no such method" unless exists $self->{$name};
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
