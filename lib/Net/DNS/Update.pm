package Net::DNS::Update;

use strict;
use vars qw($VERSION);

use Net::DNS;
# use Net::DNS::Packet;

# $Id: Update.pm,v 1.1 1997/06/13 03:42:40 mfuhr Exp $
$VERSION = $Net::DNS::VERSION;

=head1 NAME

Net::DNS::Update - Create a DNS update packet

=head1 SYNOPSIS

C<use Net::DNS::Update;>

=head1 DESCRIPTION

C<Net::DNS::Update> is a front-end for creating C<Net::DNS::Packet>
objects to be used for making DNS dynamic updates.  Programmers
should refer to RFC 2136 for the semantics of dynamic updates.

WARNING:  This code is still under development and shouldn't be
used to maintain a production nameserver.

=head1 METHODS

=head2 new

    $packet = new Net::DNS::Update("foo.com");
    $packet = new Net::DNS::Update("foo.com", "HS");

Returns a C<Net::DNS::Packet> object suitable for performing a DNS
dynamic update.  Specifically, it creates a packet with the header
opcode set to UPDATE and the zone record type to SOA (per RFC 2136,
Section 2.3).

Programs must use the C<push> method to add RRs to the prerequisite,
update, and additional sections before performing the update.

Arguments are the zone name and the class.  If omitted, the class
defaults to IN.

Future versions of C<Net::DNS> may provide a simpler interface
for making dynamic updates.

=cut

sub new {
	shift;
	my ($zone, $class) = @_;
	my ($type, $packet);

	$type  = "SOA";
	$class = "IN" unless defined $class;

	$packet = new Net::DNS::Packet($zone, $type, $class);
	if (defined $packet) {
		$packet->header->opcode("UPDATE");
		$packet->header->rd(0);
	}

	return $packet;
}

=head1 EXAMPLE

    #!/usr/local/bin/perl -w
    
    use Net::DNS;
    
    $update = new Net::DNS::Update("bar.com");
    
    # NXRRSET - Prerequisite is that no A records exist for the name.
    $update->push("pre", new Net::DNS::RR(
        Name  => "foo.bar.com",
        Class => "NONE",
        Type  => "A"));
    
    # Add two A records for the name.
    $update->push("update", new Net::DNS::RR(
        Name    => "foo.bar.com",
        Ttl     => 86400,
        Type    => "A",
        Address => "192.168.1.1"));
    
    $update->push("update", new Net::DNS::RR(
        Name    => "foo.bar.com",
        Ttl     => 86400,
        Type    => "A",
        Address => "192.168.1.2"));
    
    $res = new Net::DNS::Resolver;
    $res->nameservers("primary-master.bar.com");
    $ans = $res->send($update);
    
    if (defined $ans) {
        print $ans->header->rcode, "\n";
    }
    else {
        print $res->errorstring, "\n";
    }

=head1 BUGS

This code is still under development and shouldn't be used to maintain
a production nameserver.

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Resolver>, L<Net::DNS::Header>,
L<Net::DNS::Packet>, L<Net::DNS::Question>, L<Net::DNS::RR>, RFC 2136

=cut

1;
