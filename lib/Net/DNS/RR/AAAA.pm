package Net::DNS::RR::AAAA;

# $Id: AAAA.pm,v 1.3 1997/06/13 03:33:54 mfuhr Exp $

use strict;
use vars qw(@ISA);

use Net::DNS;

@ISA = qw(Net::DNS::RR);

sub new {
	my ($class, $self, $data, $offset) = @_;

	if ($self->{"rdlength"} > 0) {
		my @addr = unpack("\@$offset n8", $$data);
		$self->{"address"} = sprintf("%x:%x:%x:%x:%x:%x:%x:%x", @addr);
	}
	return bless $self, $class;
}

sub rdatastr {
	my $self = shift;

	return exists $self->{"address"} && $self->{"address"}
	       ? $self->{"address"}
	       : "; no data";
}

sub rr_rdata {
	my $self = shift;
	my $rdata = "";

	if (exists $self->{"address"}) {
		my @addr = split(/:/, $self->{"address"});
		$rdata .= pack("n8", map { hex $_ } @addr);
	}

	return $rdata;
}

1;
__END__

=head1 NAME

Net::DNS::RR::AAAA - DNS AAAA resource record

=head1 SYNOPSIS

C<use Net::DNS::RR>;

=head1 DESCRIPTION

Class for DNS IPv6 Address (AAAA) resource records.

=head1 METHODS

=head2 address

    print "address = ", $rr->address, "\n";

Returns the RR's address field.

=head1 BUGS

Only the preferred method of address representation ("x:x:x:x:x:x:x:x",
documented in RFC 1884, Section 2.2, Para 1) is supported.

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Resolver>, L<Net::DNS::Packet>,
L<Net::DNS::Header>, L<Net::DNS::Question>, L<Net::DNS::RR>,
RFC 1886 Section 2, RFC 1884 Section 2.2

=cut
