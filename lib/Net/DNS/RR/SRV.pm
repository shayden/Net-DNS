package Net::DNS::RR::SRV;

# $Id: SRV.pm,v 1.2 1997/02/02 08:31:25 mfuhr Exp $

use strict;
use vars qw(@ISA);

use Net::DNS;
use Net::DNS::Packet;

@ISA = qw(Net::DNS::RR);

sub new {
	my ($class, $self, $data, $offset) = @_;

	my ($priority) = unpack("\@$offset n", $$data);
	$offset += &Net::DNS::INT16SZ;
	my ($weight) = unpack("\@$offset n", $$data);
	$offset += &Net::DNS::INT16SZ;
	my ($port) = unpack("\@$offset n", $$data);
	$offset += &Net::DNS::INT16SZ;
	my($target) = Net::DNS::Packet::dn_expand($data, $offset);

	$self->{"priority"} = $priority;
	$self->{"weight"}   = $weight;
	$self->{"port"}     = $port;
	$self->{"target"}   = $target;

	return bless $self, $class;
}

sub rdatastr {
	my $self = shift;
	return "$self->{priority} $self->{weight} $self->{port} $self->{target}.";
}
1;
__END__

=head1 NAME

Net::DNS::RR::SRV - DNS SRV resource record

=head1 SYNOPSIS

C<use Net::DNS::RR>;

=head1 DESCRIPTION

Class for DNS Service (SRV) resource records.

=head1 METHODS

=head2 priority

    print "priority = ", $rr->priority, "\n";

Returns the priority for this target host.

=head2 weight

    print "weight = ", $rr->weight, "\n";

Returns the weight for this target host.

=head2 port

    print "port = ", $rr->port, "\n";

Returns the port on this target host for the service.

=head2 target

    print "target = ", $rr->target, "\n";

Returns the target host.

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Resolver>, L<Net::DNS::Packet>,
L<Net::DNS::Header>, L<Net::DNS::Question>, L<Net::DNS::RR>,
RFC 2052

=cut
