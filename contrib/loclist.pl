#!/usr/bin/perl

# for use on log:  perl -pe 's/^.*host=//; s/([a-zA-Z0-9.-]+).*/$1/' loc2earth-queries | sort -u | ./loclist.pl

# or
# egrep 'loc2earth.*host' /serv/www/logs/wn.log |
# perl -pe 's/^.*host=//; s/([a-zA-Z0-9.-]+).*/$1/' |
# sort -u | ~/loclist.pl | grep YES | mail -v -s "LOC sites" ckd

use Net::DNS;

$res = new Net::DNS::Resolver;

foreach $_ (<>) {
    chomp;
    $query = $res->query($_,"LOC");

    if (defined ($query)) {	# then we got an answer of some sort
	foreach $ans ($query->answer) {
	    if ($ans->type eq "LOC") {
		$rdatastr = $ans->rdatastr;
		print "$_ YES $rdatastr\n";
	    }
	}
    } else {
	print "$_ NO\n";
    }
}
