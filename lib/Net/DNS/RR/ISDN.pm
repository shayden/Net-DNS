package Net::DNS::RR::ISDN;

# $Id: ISDN.pm,v 1.3 1997/03/28 01:20:55 mfuhr Exp $

use strict;
use vars qw(@ISA);

use Net::DNS::Packet;

@ISA = qw(Net::DNS::RR);

sub new {
	my ($class, $self, $data, $offset) = @_;

	my ($address, $sa, $len);

	($len) = unpack("\@$offset C", $$data);
	++$offset;
	($address) = unpack("\@$offset a$len", $$data);
	$offset += $len;

	if ($len + 1 < $self->{"rdlength"}) {
		($len) = unpack("\@$offset C", $$data);
		++$offset;
		($sa) = unpack("\@$offset a$len", $$data);
		$offset += $len;
	}
	else {
		$sa = "";
	}

	$self->{"address"} = $address;
	$self->{"sa"}  = $sa;

	return bless $self, $class;
}

sub rdatastr {
	my $self = shift;
	return qq("$self->{address}" "$self->{sa}");
}
1;
__END__

=head1 NAME

Net::DNS::RR::ISDN - DNS ISDN resource record

=head1 SYNOPSIS

C<use Net::DNS::RR>;

=head1 DESCRIPTION

Class for DNS ISDN resource records.

=head1 METHODS

=head2 address

    print "address = ", $rr->address, "\n";

Returns the RR's address field.

=head2 sa

    print "subaddress = ", $rr->sa, "\n";

Returns the RR's subaddress field.

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Resolver>, L<Net::DNS::Packet>,
L<Net::DNS::Header>, L<Net::DNS::Question>, L<Net::DNS::RR>,
RFC 1183 Section 3.2

=cut
