package Net::DNS::RR::X25;

# $Id: X25.pm,v 1.2 1997/02/02 08:31:25 mfuhr Exp $

use strict;
use vars qw(@ISA);

use Net::DNS::Packet;

@ISA = qw(Net::DNS::RR);

sub new {
	my ($class, $self, $data, $offset) = @_;
	my ($psdn, $len);

	($len) = unpack("\@$offset C", $$data);
	++$offset;
	($psdn) = unpack("\@$offset a$len", $$data);
	$offset += $len;

	$self->{"psdn"} = $psdn;

	return bless $self, $class;
}

sub rdatastr {
	my $self = shift;
	return qq("$self->{psdn}");
}
1;
__END__

=head1 NAME

Net::DNS::RR::X25 - DNS X25 resource record

=head1 SYNOPSIS

C<use Net::DNS::RR>;

=head1 DESCRIPTION

Class for DNS X25 resource records.

=head1 METHODS

=head2 psdn

    print "psdn = ", $rr->psdn, "\n";

Returns the PSDN address.

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Resolver>, L<Net::DNS::Packet>,
L<Net::DNS::Header>, L<Net::DNS::Question>, L<Net::DNS::RR>,
RFC 1183 Section 3.1

=cut
