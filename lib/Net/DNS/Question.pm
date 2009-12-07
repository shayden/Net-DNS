package Net::DNS::Question;

use strict;
use vars qw($VERSION $AUTOLOAD);

use Carp;
use Net::DNS;

# $Id: Question.pm,v 1.2 1997/02/02 08:32:41 mfuhr Exp $
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

=head2 qname

    print "qname = ", $question->qname, "\n";

Returns the domain name.

=head2 qtype

    print "qtype = ", $question->qtype, "\n";

Returns the record type.

=head2 qclass

    print "qclass = ", $question->qclass, "\n";

Returns the record class.

=cut

sub AUTOLOAD {
	my $self = shift;
	my $name = $AUTOLOAD;
	$name =~ s/.*://;

	Carp::confess "$name: no such method" unless exists $self->{$name};
	return $self->{$name};
}

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
