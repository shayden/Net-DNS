package Net::DNS::Question;

use strict;
use vars qw($VERSION $AUTOLOAD);

use Carp;
use Net::DNS;

# $Id: Question.pm,v 1.4 1997/04/19 17:48:07 mfuhr Exp $
$VERSION = $Net::DNS::VERSION;

=head1 NAME

Net::DNS::Question - DNS question class

=head1 SYNOPSIS

C<use Net::DNS::Question>

=head1 DESCRIPTION

A C<Net::DNS::Question> object represents a record in the
question section of a DNS packet.

=head1 METHODS

=head2 new

    $question = new Net::DNS::Question("foo.com", "MX", "IN");

Creates a question object from the domain, type, and class passed
as arguments.

=cut

sub new {
	my $class = shift;
	my %self = (
		"qname"		=> undef,
		"qtype"		=> undef,
		"qclass"	=> undef,
	);

	my ($qname, $qtype, $qclass) = @_;
	$self{"qname"} = $qname;
	$self{"qtype"} = $qtype;
	$self{"qclass"} = $qclass;

	bless \%self, $class;
}

#
# Some people have reported that Net::DNS dies because AUTOLOAD picks up
# calls to DESTROY.
#
sub DESTROY {}

=head2 qname, zname

    print "qname = ", $question->qname, "\n";

Returns the domain name.  In dynamic update packets, this field is
known as C<zname> and refers to the zone name.

=head2 qtype, ztype

    print "qtype = ", $question->qtype, "\n";

Returns the record type.  In dymamic update packets, this field is
known as C<ztype> and refers to the zone type (must be SOA).

=head2 qclass, zclass

    print "qclass = ", $question->qclass, "\n";

Returns the record class.  In dynamic update packets, this field is
known as C<zclass> and refers to the zone's class.

=cut

sub AUTOLOAD {
	my $self = shift;
	my $name = $AUTOLOAD;
	$name =~ s/.*://;

	Carp::confess "$name: no such method" unless exists $self->{$name};
	return $self->{$name};
}

sub zname  { my $self = shift; $self->qname(@_);  }
sub ztype  { my $self = shift; $self->qtype(@_);  }
sub zclass { my $self = shift; $self->qclass(@_); }

=head2 print

    $question->print;

Prints the question record on the standard output.

=cut

sub print {
	my $self = shift;
	print "$self->{qname}.\t$self->{qclass}\t$self->{qtype}\n";
}

=head2 data

    $qdata = $question->data;

Returns the question record in binary format suitable for inclusion
in a DNS packet.

=cut

sub data {
	my $self = shift;
	my $data = "";

	my $elem;
	foreach $elem (split(/\./, $self->{"qname"})) {
		$data .= pack("C a*", length($elem), $elem);
	}
	$data .= pack("C", 0);

	$data .= pack("n", $Net::DNS::typesbyname{uc($self->{"qtype"})});
	$data .= pack("n", $Net::DNS::classesbyname{uc($self->{"qclass"})});
	
	return $data;
}

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Resolver>, L<Net::DNS::Packet>,
L<Net::DNS::Header>, L<Net::DNS::RR>,
RFC 1035 Section 4.1.2

=cut

1;
