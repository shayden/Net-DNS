package Net::DNS::RR::MINFO;

# $Id: MINFO.pm,v 1.2 1997/02/02 08:31:25 mfuhr Exp $

use strict;
use vars qw(@ISA);

use Net::DNS::Packet;

@ISA = qw(Net::DNS::RR);

sub new {
	my ($class, $self, $data, $offset) = @_;

	my ($rmailbx, $emailbx);
	($rmailbx, $offset) = Net::DNS::Packet::dn_expand($data, $offset);
	($emailbx, $offset) = Net::DNS::Packet::dn_expand($data, $offset);
	$self->{"rmailbx"} = $rmailbx;
	$self->{"emailbx"} = $emailbx;
	return bless $self, $class;
}

sub rdatastr {
	my $self = shift;
	return "$self->{rmailbx}. $self->{emailbx}.";
}
1;
__END__

=head1 NAME

Net::DNS::RR::MINFO - DNS MINFO resource record

=head1 SYNOPSIS

C<use Net::DNS::RR>;

=head1 DESCRIPTION

Class for DNS Mailbox Information (MINFO) resource records.

=head1 METHODS

=head2 rmailbx

    print "rmailbx = ", $rr->rmailbx, "\n";

Returns the RR's responsible mailbox field.  See RFC 1035.

=head2 emailbx

    print "emailbx = ", $rr->emailbx, "\n";

Returns the RR's error mailbox field.

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Resolver>, L<Net::DNS::Packet>,
L<Net::DNS::Header>, L<Net::DNS::Question>, L<Net::DNS::RR>,
RFC 1035 Section 3.3.7

=cut
