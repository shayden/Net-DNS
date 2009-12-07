package Net::DNS::Resolver;

=head1 NAME

Net::DNS::Resolver - DNS resolver class

=head1 SYNOPSIS

C<use Net::DNS::Resolver;>

=head1 DESCRIPTION

Instances of the C<Net::DNS::Resolver> class represent resolver objects.
A program can have multiple resolver objects, each maintaining its
own state information such as the nameservers to be queried, whether
recursion is desired, etc.

Resolver configuration is read from the following files, in the
order indicated:

    /etc/resolv.conf
    $HOME/.resolv.conf
    ./.resolv.conf

The following keywords are recognized in resolver configuration files:

=over 4

=item B<domain>

The default domain.

=item B<search>

A space-separated list of domains to put in the search list.

=item B<nameserver>

A space-separated list of nameservers to query.

=back

Files except for F</etc/resolv.conf> must be owned by the effective
userid running the program or they won't be read.  In addition, several
environment variables can also contain configuration information;
see L</ENVIRONMENT>.

=head1 METHODS

=cut

use strict;
use vars qw(
	$VERSION
	$resolv_conf
	$dotfile
	@confpath
	%default
	%global
	$AUTOLOAD
);

use Carp;
use Socket;
use IO::Socket;
use Net::DNS;
use Net::DNS::Packet;

# $Id: Resolver.pm,v 1.3 1997/02/03 05:20:22 mfuhr Exp $
$VERSION = $Net::DNS::VERSION;

#------------------------------------------------------------------------------
# Configurable defaults.
#------------------------------------------------------------------------------

$resolv_conf = "/etc/resolv.conf";
$dotfile     = ".resolv.conf";

@confpath    = (
	$ENV{HOME},
	".",
);

%default = (
	"nameservers"	=> [],
	"port"		=> "domain(53)",
	"domain"	=> "",
	"searchlist"	=> [],
	"retrans"	=> 5,
	"retry"		=> 4,
	"usevc"		=> 0,
	"stayopen"	=> 0,
	"igntc"		=> 0,
	"recurse"	=> 1,
	"defnames"	=> 1,
	"dnsrch"	=> 1,
	"debug"		=> 0,
	"errorstring"	=> "unknown error or no error",
);

%global = (
	"initialized"	=> 0,
	"id"		=> int(rand(65535)),
);

BEGIN {
	srand(time() ^ ($$ + ($$ << 15)));
}

=head2 new

    $res = new Net::DNS::Resolver;

Creates a new DNS resolver object.

=cut

sub new {
	my $class = shift;

	res_init() unless $global{"initialized"};

	my $self = { %default };
	return bless $self, $class;
}

sub res_init {
	$global{"initialized"} = 1;

	read_config($resolv_conf) if (-f $resolv_conf) and (-r $resolv_conf);

	my $dir;
	foreach $dir (@confpath) {
		my $file = "$dir/$dotfile";
		read_config($file) if (-f $file) and (-r $file) and (-o $file);
	}

	read_env();

	if (!$default{"domain"} && @{$default{"searchlist"}}) {
		$default{"domain"} = $default{"searchlist"}[0];
	}
	elsif (!@{$default{"searchlist"}} && $default{"domain"}) {
		$default{"searchlist"} = [ $default{"domain"} ];
	}
}

sub read_config {
	my $file = shift;
	open(FILE, $file) or Carp::confess "can't open $file: $!";
	while (<FILE>) {
		next if /^\s*[;#]/;

		SWITCH: {
			/^\s*domain\s+(\S+)/ && do {
				$default{"domain"} = $1;
				last SWITCH;
			};

			/^\s*search\s+(.*)/ && do {
				$default{"searchlist"} = [split(" ", $1)];
				last SWITCH;
			};

			/^\s*nameserver\s+(.*)/ && do {
				$default{"nameservers"} = [split(" ", $1)];
				last SWITCH;
			};
		}
	}
	close FILE;
}

sub read_env {
	$default{"nameservers"} = [ split(" ", $ENV{"RES_NAMESERVERS"}) ]
		if exists $ENV{"RES_NAMESERVERS"};

	$default{"searchlist"} = [ split(" ", $ENV{"RES_SEARCHLIST"}) ]
		if exists $ENV{"RES_SEARCHLIST"};
	
	$default{"domain"} = $ENV{"LOCALDOMAIN"} if exists $ENV{"LOCALDOMAIN"};

	if (exists $ENV{"RES_OPTIONS"}) {
		my @env = split(" ", $ENV{"RES_OPTIONS"});
		foreach (@env) {
			my($name, $val) = split(/:/);
			$val = 1 unless defined $val;
			$default{$name} = $val if exists $default{$name};
		}
	}
}

=head2 print

    $res->print;

Prints the resolver state on the standard output.

=cut

sub print {
	my $self = shift;

	print ";; RESOLVER state:\n";
	print ";;  domain      = $self->{domain}\n";
	print ";;  searchlist  = @{$self->{searchlist}}\n";
	print ";;  nameservers = @{$self->{nameservers}}\n";
	print ";;  port        = $self->{port}\n";
	print ";;  retrans  = $self->{retrans}  retry    = $self->{retry}\n";
	print ";;  usevc    = $self->{usevc}  stayopen = $self->{stayopen}",
	      "    igntc = $self->{igntc}\n";
	print ";;  defnames = $self->{defnames}  dnsrch   = $self->{dnsrch}\n";
	print ";;  recurse  = $self->{recurse}  debug    = $self->{debug}\n";
}

sub nextid {
	return $global{"id"}++;
}

=head2 searchlist

    @searchlist = $res->searchlist;
    $res->searchlist("foo.com", "bar.com", "baz.org");

Gets or sets the resolver search list.

=cut

sub searchlist {
	my $self = shift;
	$self->{"searchlist"} = [ @_ ] if @_;
	return @{$self->{"searchlist"}};
}

=head2 nameservers

    @nameservers = $res->nameservers;
    $res->nameservers("192.168.1.1", "192.168.2.2", "192.168.3.3");

Gets or sets the nameservers to be queried.

=head2 port

    print "sending queries to port ", $res->port, "\n";
    $res->port(9732);

Gets or sets the port to which we send queries.  This can be useful
for testing a nameserver running on a non-standard port.  The
default is port 53.

=cut

sub nameservers {
	my $self = shift;
	my $defres = new Net::DNS::Resolver;

	if (@_) {
		my @a;
		my $ns;
		foreach $ns (@_) {
			my $packet = $defres->query($ns);
			$self->errorstring($defres->errorstring);
			if (defined($packet)) {
				push(@a, ($packet->answer)[0]->address);
			}
		}
		$self->{"nameservers"} = [ @a ];
	}

	return @{$self->{"nameservers"}};
}

=head2 search

    $packet = $res->search("mailhost");
    $packet = $res->search("mailhost.foo.com");
    $packet = $res->search("192.168.1.1");
    $packet = $res->search("foo.com", "MX");
    $packet = $res->search("user.passwd.foo.com", "TXT", "HS");

Performs a DNS query for the given name, applying the searchlist
if appropriate.  The search algorithm is as follows:

=over 4

=item 1.

If the name contains at least one dot, try it as is.

=item 2.

If the name doesn't end in a dot then append each item in
the search list to the name.  This is only done if B<dnsrch>
is true.

=item 3.

If the name doesn't contain any dots, try it as is.

=back

The record type and class can be omitted; they default to A and
IN.  If the name looks like an IP address (4 dot-separated numbers),
then an appropriate PTR query will be performed.

Returns a C<Net::DNS::Packet> object, or C<undef> if no answers
were found.

=cut

sub search {
	my $self = shift;
	my ($name, $type, $class) = @_;
	my $ans;

	$type  = "A"  unless defined($type);
	$class = "IN" unless defined($class);

	# If the name looks like an IP address then do an appropriate
	# PTR query.
	if ($name =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
		$name = "$4.$3.$2.$1.in-addr.arpa.";
		$type = "PTR";
	}

	# If the name contains at least one dot then try it as is first.
	if (index($name, ".") >= 0) {
		print ";; search($name, $type, $class)\n" if $self->{"debug"};
		$ans = $self->query($name, $type, $class);
		return $ans if (defined $ans) && ($ans->header->ancount > 0);
	}

	# If the name doesn't end in a dot then apply the search list.
	my $domain;
	if (($name !~ /\.$/) && $self->{"dnsrch"}) {
		foreach $domain (@{$self->{"searchlist"}}) {
			my $newname = "$name.$domain";
			print ";; search($newname, $type, $class)\n"
				if $self->{"debug"};
			$ans = $self->query($newname, $type, $class);
			return $ans if (defined $ans) && ($ans->header->ancount > 0);
		}
	}

	# Finally, if the name has no dots then try it as is.
	if (index($name, ".") < 0) {
		print ";; search($name, $type, $class)\n" if $self->{"debug"};
		$ans = $self->query("$name.", $type, $class);
		return $ans if (defined $ans) && ($ans->header->ancount > 0);
	}

	# No answer was found.
	return undef;
}

=head2 query

    $packet = $res->query("mailhost");
    $packet = $res->query("mailhost.foo.com");
    $packet = $res->query("192.168.1.1");
    $packet = $res->query("foo.com", "MX");
    $packet = $res->query("user.passwd.foo.com", "TXT", "HS");

Performs a DNS query for the given name; the search list is not
applied.  If the name doesn't contain any dots and B<defnames>
is true then the default domain will be appended.

The record type and class can be omitted; they default to A and
IN.  If the name looks like an IP address (4 dot-separated numbers),
then an appropriate PTR query will be performed.

Returns a C<Net::DNS::Packet> object, or C<undef> if no answers
were found.

=cut

sub query {
	my $self = shift;
	my ($name, $type, $class) = @_;

	$type  = "A"  unless defined($type);
	$class = "IN" unless defined($class);

	# If the name doesn't contain any dots then append the default domain.
	if ((index($name, ".") < 0) && $self->{"defnames"}) {
		$name .= ".$self->{domain}";
	}

	# If the name looks like an IP address then do an appropriate
	# PTR query.
	if ($name =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
		$name = "$4.$3.$2.$1.in-addr.arpa";
		$type = "PTR";
	}

	print ";; query($name, $type, $class)\n" if $self->{"debug"};
	my $packet = new Net::DNS::Packet($name, $type, $class);
	my $ans = $self->send($packet);

	return (defined($ans) && ($ans->header->ancount > 0)) ? $ans : undef;
}

=head2 send

    $packet = $res->send($query_packet);
    $packet = $res->send("mailhost.foo.com");
    $packet = $res->send("foo.com", "MX");
    $packet = $res->send("user.passwd.foo.com", "TXT", "HS");

Performs a DNS query for the given name.  Neither the searchlist
nor the default domain will be appended.  

The record type and class can be omitted; they default to A and
IN.  If the name looks like an IP address (4 dot-separated numbers),
then an appropriate PTR query will be performed.

Returns a C<Net::DNS::Packet> object whether there were any
answers or not.  Use $packet->ancount or $packet->answer
to find out if there were any records in the answer section.
Returns undef if there was an error.

=cut

sub send {
	my $self = shift;
	my $retrans = $self->{"retrans"};
	my $timeout = $retrans;
	my ($ns, @ns);
	my $rin = "";
	my $rout;
	my ($i, $j);
	my $packet;

	$self->errorstring($default{"errorstring"});

	if (ref($_[0]) eq "Net::DNS::Packet") {
		$packet = shift;
	}
	else {
		my ($name, $type, $class) = @_;

		$type  = "A"  unless defined($type);
		$class = "IN" unless defined($class);

		# If the name looks like an IP address then do an appropriate
		# PTR query.
		if ($name =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
			$name = "$4.$3.$2.$1.in-addr.arpa.";
			$type = "PTR";
		}

		$packet = new Net::DNS::Packet($name, $type, $class);
	}

	$packet->header->rd($self->{"recurse"});

	@ns = map {
		IO::Socket::INET->new(PeerAddr => $_,
				      PeerPort => $self->{"port"},
				      Proto    => "udp");
	} @{$self->{"nameservers"}};

	unless (defined(@ns) && @ns) {
		$self->errorstring("no nameservers");
		return undef;
	}

	# Perform each round of retries.
	for ($i = 0;
	     $i < $self->{"retry"};
	     ++$i, $retrans *= 2, $timeout = int($retrans / ($#ns + 1))) {

		$timeout = 1 if ($timeout < 1);

		# Try each nameserver.
		foreach $ns (@ns) {
			print ";; send(", $ns->peerhost, ":", $ns->peerport, ")\n"
				if $self->{"debug"};

			$rin = select_list(@ns);

			# Failure needs to be more graceful.
			$ns->send($packet->data) or Carp::confess "send: $!";

			select($rout=$rin, undef, undef, $timeout);

			# If one of the nameservers answered, which was it?
			my $ns2;
			my $j = 0;
			foreach $ns2 (@ns) {
				if (vec($rout, $ns2->fileno, 1) == 1) {
					my $buf = "";
					if ($ns2->recv($buf, &Net::DNS::PACKETSZ)) {
						print ";; answer from ",
						      $ns2->peerhost, ":",
						      $ns2->peerport, " : ",
						      length($buf), " bytes\n"
							if $self->{"debug"};
						my $ans = new Net::DNS::Packet(\$buf);
						$ans->print if $self->{"debug"};
						$self->errorstring($ans->header->rcode);
						return $ans;
					}
					else {
						$self->errorstring($!);
						print ";; ERROR(",
						      $ns[$j]->peerhost, ":",
						      $ns[$j]->peerport, "): ",
						      $self->errorstring, "\n"
							if $self->{"debug"};

						# Delete this nameserver.
						splice(@ns, $j, 1);
						return undef unless @ns;
					}
				}
			}
			continue {
				++$j;
			}
		}
	}

	$self->errorstring("query timed out");
	return undef;
}

sub select_list {
	my $retval = "";
	foreach (@_) {
		vec($retval, $_->fileno, 1) = 1;
	}
	return $retval;
}

=head2 retrans

    print "retrans interval", $res->retrans, "\n";
    $res->retrans(3);

Get or set the retransmission interval.  The default is 5.

=head2 retry

    print "number of tries: ", $res->retry, "\n";
    $res->retry(2);

Get or set the number of times to try the query.  The default is 4.

=head2 recurse

    print "recursion flag: ", $res->recurse, "\n";
    $res->recurse(0);

Get or set the recursion flag.  If this is true, nameservers will
be requested to perform a recursive query.  The default is true.

=head2 defnames

    print "defnames flag: ", $res->defnames, "\n";
    $res->defnames(0);

Get or set the defnames flag.  If this is true, calls to B<query> will
append the default domain to names that contain no dots.  The default
is true.

=head2 dnsrch

    print "dnsrch flag: ", $res->dnsrch, "\n";
    $res->dnsrch(0);

Get or set the dnsrch flag.  If this is true, calls to B<search> will
apply the search list.  The default is true.

=head2 debug

    print "debug flag: ", $res->debug, "\n";
    $res->debug(1);

Get or set the debug flag.  If this is true, calls to B<search>,
B<query>, and B<send> will print debugging information on the standard
output.  The default is false.

=head2 usevc (not yet implemented)

    print "usevc flag: ", $res->usevc, "\n";
    $res->usevc(1);

Get or set the usevc flag.  If true, then queries will be performed
using virtual circuits (TCP) instead of datagrams (UDP).  The default
is false.

=head2 igntc (not yet implemented)

    print "igntc flag: ", $res->igntc, "\n";
    $res->igntc(1);

Get or set the igntc flag.  If true, truncated packets will be
ignored.  If false, truncated packets will cause the query to
be retried using TCP.  The default is false.

=head2 errorstring

    print "query status: ", $res->errorstring, "\n";

Returns a string containing the status of the most recent query.

=cut

sub AUTOLOAD {
	my $self = shift;
	my $name = $AUTOLOAD;
	$name =~ s/.*://;

	Carp::confess "$name: no such method" unless exists $self->{$name};
	$self->{$name} = shift if @_;
	return $self->{$name};
}

=head1 ENVIRONMENT

The following environment variables can also be used to configure
the resolver:

=head2 RES_NAMESERVERS

    # Bourne Shell
    RES_NAMESERVERS="192.168.1.1 192.168.2.2 192.168.3.3"
    export RES_NAMESERVERS

    # C Shell
    setenv RES_NAMESERVERS "192.168.1.1 192.168.2.2 192.168.3.3"

A space-separated list of nameservers to query.

=head2 RES_SEARCHLIST

    # Bourne Shell
    RES_SEARCHLIST="foo.com bar.com baz.org"
    export RES_SEARCHLIST

    # C Shell
    setenv RES_SEARCHLIST "foo.com bar.com baz.org"

A space-separated list of domains to put in the search list.

=head2 LOCALDOMAIN

    # Bourne Shell
    LOCALDOMAIN=foo.com
    export LOCALDOMAIN

    # C Shell
    setenv LOCALDOMAIN foo.com

The default domain.

=head2 RES_OPTIONS

    # Bourne Shell
    RES_OPTIONS="retrans:3 retry:2 debug"
    export RES_OPTIONS

    # C Shell
    setenv RES_OPTIONS "retrans:3 retry:2 debug"

A space-separated list of resolver options to set.  Options that
take values are specified as I<option>:I<value>.

=head1 BUGS

Only UDP queries are supported in this version.  Zone transfers
can't be done until TCP queries are implemented.

Error reporting needs to be improved.

=head1 COPYRIGHT

Copyright (c) 1997 Michael Fuhr.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself. 

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Packet>, L<Net::DNS::Header>,
L<Net::DNS::Question>, L<Net::DNS::RR>, L<resolver(5)>,
RFC 1035

=cut

1;
