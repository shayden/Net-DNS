package Net::DNS::RR::MX;

# $Id: MX.pm,v 1.2 1997/02/02 08:31:25 mfuhr Exp $

use strict;
use vars qw(@ISA);

use Net::DNS;
use Net::DNS::Packet;

@ISA = qw(Net::DNS::RR);

sub new {
	my ($class, $self, $data, $offset) = @_;

	my ($preference) = unpack("\@$offset n", $$data);
	$offset += &Net::DNS::INT16SZ;
	my($exchange) = Net::DNS::Packet::dn_expand($data, $offset);
	$self->{"preference"} = $preference;
	$self->{"exchange"} = $exchange;
	return bless $self, $class;
}

sub rdatastr {
	my $self = shift;
	return "$self->{preference} $self->{exchange}.";
}
1;
__END__

=head1 NAME

Net::DNS::RR::MX - DNS MX resource record

=head1 SYNOPSIS

C<use Net::DNS::RR>;

=head1 DESCRIPTION

Class for DNS Mail Exchanger (MX) resource records.

=head1 METHODS

=head2 preference

    print "preference = ", $rr->preference, "\n";

Returns the preference for this mail exchange.

=head2 exchange

    print "exchange = ", $rr->exchange, "\n";

Returns name of this mail exchange.

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Resolver>, L<Net::DNS::Packet>,
L<Net::DNS::Header>, L<Net::DNS::Question>, L<Net::DNS::RR>,
RFC 1035 Section 3.3.9

=cut
