#!/opt/perl5/bin/perl
#
# $Id: dnslookup.cgi,v 2.1 1997/10/22 21:18:56 skh Exp $
#
# This script is a CGI interface to the domain name system.  This version
# of the script requires that you have the Net::DNS module from CPAN installed
# and be running perl5.003 or higher.
#
# If you have suggestions or improvements feel free to send 'em to me.
#
# Kent Hamilton
#   Work:  <KHamilton@Hunter.COM> 
#   Home:  <KentH@HNS.St-Louis.Mo.US>
#    URL:  http://www2.hunter.com/~skh/
#

$| = 0;

use File::Basename;
use Net::DNS;

####################################
# Set your defaults here folks.
####################################
$DEBUG = 0;
$nameserver = "ns.hunter.com";
$lookuptype = "name_info";
$lookup = "";
$formurl = "/~skh/scripts/dnslookup.html";
$uparrowurl = "/~skh/images/up.gif";

#
# Get our input from the HTML form....
#
read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});

@pairs = split(/&/, $buffer);

foreach $pair (@pairs) {
    # Set this to the characters valid for your input.  Try
    # not to use anything toooo nasty.  (IE `.<>; etc)
    $ok_chars = "a-zA-Z0-9_\-\.";
    ($name, $value) = split(/=/, $pair);
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    $value =~ s/<([^>]|\n)*>//g;
    $value =~ s/<//g;
    $value =~ s/>//g;
    $value =~ s/`;/_/g;
# Strip out everything not an allowed character (translate it to a '_').
    $value =~ eval "tr/[$ok_chars]/_/c";
    $FORM{$name} = $value;
}

#
# Init our Resolver info.
# If they entered a name server then use it.
#
my $res = new Net::DNS::Resolver;

if ($FORM{'n_server'}) {
    my $nameserver = $FORM{'n_server'};
    $res->nameservers($nameserver);
}

#
# Some default values.
#
$lookup = $FORM{'lookup_val'};
$lookuptype = $FORM{'choice'};
$type  ||= "A";
$class ||= "IN";

#
# They didn't enter anything to search for so yell at 'em.
#
if ( $lookup eq "" ) {
    print "Content-type: text/html\n\n";
    print "<HTML>\n";
    print "<HEAD>\n";
    print "<TITLE>DNS Lookup Error!</TITLE>\n";
    print "</HEAD>\n";
    print "<BODY BGCOLOR=\"#ffffff\">\n";
    print "<CENTER><P><BR><BR><BR>\n";
    print "You must enter at least a name or IP address to search for.<BR>\n";
    print "<P><BR><BR>\n";
    print "Return to the <A HREF=\"$formurl\">DNS Lookup</A> form.\n";
    print "</BODY></HTML>\n";
    exit;
}

#
# Set the type of lookup to do.
# Some of these get reset below but....
#
if ($lookuptype eq 'name_info' ) {
    $type = "ANY";
    $qstring = 'any information';
} elsif ($lookuptype eq 'ns_lookup') {
    $type = "NS";
    $qstring = 'name server(s)';
} elsif ($lookuptype eq 'domain_list') {
    $type = "AXFR";
    $qstring = 'a zone listing';
} elsif ($lookuptype eq 'soa') {
    $type = "SOA";
    $qstring = 'the start of authority information';
} elsif ($lookuptype eq 'subnet_list') {
    $type = "AXFR";
    $qstring = 'a subnet listing';
    if ( $lookup =~ m/^\d+(\.\d+){0,3}$/ ) {
        $reverse = join ('.', reverse (split ('\.', $lookup ))) . '.in-addr.arpa';
        $lookup = $reverse;
    }
} elsif ($lookuptype eq 'mail_exch') {
    $type = "MX";
    $qstring = 'the mail exchangers';
} else {
    $type = "ANY";
    $qstring = 'any information';
}

if ($DEBUG) {
    print "Content-type: text/html\n\n";
    print "<HTML>\n";
    print "<HEAD>\n";
    print "<TITLE>DNS Lookup Debug!</TITLE>\n";
    print "</HEAD>\n";
    print "<BODY BGCOLOR=\"#ffffff\">\n";
    print "<CENTER><P><BR><BR><BR>\n";
    print "lookup = $lookup<BR>\n";
    print "lookuptype = $lookuptype<BR>\n";
    print "nameserver = $nameserver<BR>\n";
    print "FORM('choice') = $FORM{'choice'}<BR>\n";
    print "FORM('n_server') = $FORM{'n_server'}<BR>\n";
    print "FORM('lookup_val') = $FORM{'lookup_val'}<BR>\n";
}

#
# Do a zone transfer for either a forward or reverse zone.
#
if ($lookuptype eq "domain_list" || $lookuptype eq "subnet_list" ) {
    my @zone = $res->axfr($lookup, $class);
        if (defined(@zone) && @zone) {
            &html_header;
            &html_question($qstring, $lookup, $nameserver);
            print "<TABLE>\n";
            foreach (@zone) {
                $_->print;
                print "<BR>\n";
            }
            &html_footer;
        } else {
            &html_header;
            &html_queryerr("Zone transfer failed: ", $res->errorstring);
            &html_footer;
            exit;
        }
} else {
#
# This is the "anything else" case.
#
    my $packet = $res->send($lookup, $type, $class);
    if (defined($packet)) {
        &html_header;
        &html_question( $qstring, $lookup, $nameserver);
        if (! $packet->header->aa) {
            print "<P><BR><B>Non-authoritative answer</B><BR><BR>\n";
        }
        $anscount = $packet->header->ancount;
        if ( $anscount gt 0 ) {
            flush;
            @answer = $packet->answer;
            print "<TABLE>\n";
            print "<TR>\n";
            print "<TH>Search String";
            print "<TH>Result Type";
            print "<TH>Result Data";
            print "<TH> </TH>";
            print "</TR>\n";
            foreach $rr ( @answer ) {
                &print_record( $rr );
            }
            print "</TABLE>";
            print "</CENTER>";
        } else {
            &html_noresponse;
            exit;
        }
        &html_footer;
    } else {
        &html_header;
        &html_queryerr("Query failed: ", $res->errorstring);
        &html_footer;
        exit;
    }
}
exit;

sub html_header {
    print "Content-type: text/html\n\n";
    print "<HTML>\n<HEAD>\n";
    print "<TITLE>Domain Name Server Query Results</TITLE>\n";
    print "<LINK REL=STYLESHEET TYPE=\"text/css\" HREF=\"/stylesheets/standard.html\">";
    print "</HEAD>\n<BODY BGCOLOR=\"#ffffff\">\n\n";
    print "<CENTER>";
    print "<H1 CLASS=green>Domain Name Server Query Results</H1>\n";
    print "</CENTER>";
    print "<P><HR NOSHADE>\n";
    print "<FONT FACE=\"Arial\" SIZE=\"2\" COLOR=\"blue\">";
}


sub html_footer {
    print "<P>\n<HR NOSHADE>\n<P>\n";
    print "<A HREF=\"$formurl\">";
    print "<IMG SRC=\"$uparrowurl\"> Return to the DNS Form</A>\n";
    print "<P>\n</BODY>\n</HTML>\n";
}

sub html_question {
    my $qstring = shift;
    my $lookup = shift;
    my $nameserver = shift;
    print "<BR>\n";
    print "The question you asked was:<BR>\n";
    printf "Lookup %s for %s at %s.<BR>\n", $qstring, $lookup, $nameserver;
    print "<BR><HR NOSHADE><BR>\n";
}

sub html_queryerr {
    my $errstr = shift;
    my $resstr = shift;
    printf "<FONT FACE=\"Arial\" SIZE=\"2\" COLOR=\"blue\">";
    printf "<CENTER>\n";
    printf "<BR>%s %s<BR>\n", $errstr, $resstr;
    printf "<P></CENTER>\n<HR NOSHADE>\n<P>\n";
    printf "<A HREF=\"$formurl\">";
    printf "<IMG SRC=\"$uparrowurl\"> Return to the DNS Form</A>\n";
    printf "<P>\n</BODY>\n</HTML>\n";
    exit;
}

sub html_noresponse {
    print "<FONT FACE=\"Arial\" SIZE=\"2\" COLOR=\"blue\">";
    print "<CENTER>\n";
    print "<BR>No results were returned for this query<BR>\n";
    print "<P></CENTER>\n<HR NOSHADE>\n<P>\n";
    print "<A HREF=\"$formurl\">";
    print "<IMG SRC=\"$uparrowurl\"> Return to the DNS Form</A>\n";
    print "<P>\n</BODY>\n</HTML>\n";
    exit;
}

sub print_record {
    my $rr = shift;

    if ( $rr->type eq "MX" ) {
        print "<TR>\n";
        &print_mx($rr);
        print "</TR>\n";
    } elsif ( $rr->type eq "SOA") {
        print "<TR>\n";
        &print_soa($rr);
        print "</TR>\n";
    } elsif ( $rr->type eq "NS") {
        print "<TR>\n";
        &print_ns($rr);
        print "</TR>\n";
    } elsif ( $rr->type eq "HINFO") {
        print "<TR>\n";
        &print_hinfo($rr);
        print "</TR>\n";
    } else {
        print "<TR>\n";
        &print_any($rr);
        print "</TR>\n";
    }
}

sub print_soa {
    my $soa = shift;
    printf "<TABLE>\n";
    printf "<TR>\n";
    printf "<TD>  </TD>";
    printf "<TD>Authoritative Server:</TD>";
    printf "<TD>%s</TD>",$soa->mname;
    printf "<TR>\n";
    printf "<TD>   </TD>";
    printf "<TD>  Responsible Person:</TD>";
    printf "<TD>%s</TD>",$soa->rname;
    printf "<TR>\n";
    printf "<TD>   </TD>";
    printf "<TD>  Zone Serial Number:</TD>\n";
    printf "<TD>%s</TD>",$soa->serial;
    printf "<TR>\n";
    printf "<TD>   </TD>";
    printf "<TD>    Refresh Interval:</TD>\n";
    printf "<TD>%s</TD>",$soa->refresh;
    printf "<TR>\n";
    printf "<TD>   </TD>";
    printf "<TD>      Retry Interval:</TD>\n";
    printf "<TD>%s</TD>",$soa->retry;
    printf "<TR>\n";
    printf "<TD>   </TD>";
    printf "<TD>     Expire Interval:</TD>\n";
    printf "<TD>%s</TD>",$soa->expire;
    printf "<TR>\n";
    printf "<TD>   </TD>";
    printf "<TD>Minimum Time to Live:</TD>\n";
    printf "<TD>%s</TD>",$soa->minimum;
    printf "</TR>\n";
}

sub print_mx {
    my $mx = shift;

    printf "<TR>\n";
    printf "<TD>%s</TD>\n", $mx->name;
    printf "<TD>%s</TD>\n", $mx->type;
    printf "<TD>%s</TD>\n", $mx->preference;
    printf "<TD>%s</TD>\n", $mx->exchange;
    printf "</TR>\n";
}

sub print_ns {
    my $ns = shift;
  
    printf "<TR>\n";
    printf "<TD>%s</TD>\n", $ns->name;
    printf "<TD>%s</TD>\n", $ns->type;
    printf "<TD>%s</TD>\n", $ns->nsdname;
    printf "</TR>\n";
}

sub print_hinfo {
    my $hinfo = shift;

    printf "<TR>\n";
    printf "<TD>%s</TD>\n", $hinfo->name;
    printf "<TD>%s</TD>\n", $hinfo->type;
    printf "<TD>CPU: %s</TD>\n", $hinfo->cpu;
    printf "<TD>O/S: %s</TD>\n", $hinfo->os;
    printf "</TR>\n";
}

sub print_any {
    my $rr = shift;

    printf "<TR>\n";
    printf "<TD>%s</TD>\n", $rr->name;
    printf "<TD>%s</TD>\n", $rr->type;
    printf "<TD>%s</TD>\n", $rr->rdatastr;
    printf "</TR>\n";
}

