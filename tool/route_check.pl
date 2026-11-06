#!/usr/bin/perl
# Route wiring check: every context.go/push/pushReplacement target must match
# a defined route path (allowing :param segments).
use strict;
use warnings;
use File::Find;

my (@routes, @navs);

open my $rf, '<', 'lib/core/routing/app_router.dart' or die "router missing\n";
while (my $l = <$rf>) {
    push @routes, $1 if $l =~ /path:\s*'([^']+)'/;
}
close $rf;

find(sub {
    return unless /\.dart$/;
    my $file = $File::Find::name;
    open my $fh, '<', $_ or return;
    while (my $l = <$fh>) {
        while ($l =~ /context\.(?:go|push|pushReplacement|replace)\(\s*'([^']+)'/g) {
            push @navs, [$1, $file];
        }
    }
    close $fh;
}, 'lib');

my %defined = map { $_ => 1 } @routes;
my $bad = 0;
for my $nav (@navs) {
    my ($p, $f) = @$nav;
    $p =~ s/\?.*$//;                 # strip query string (routes match on path only)
    $p =~ s/\$\{[^}]+\}/PARAM/g;      # runtime interpolation -> placeholder
    next if $defined{$p};
    # Match routes with :param segments against PARAM placeholders.
    my $ok = 0;
    for my $r (@routes) {
        (my $pat = $r) =~ s/:[^\/]+/PARAM/g;
        $pat =~ s{\$}{\$}g;
        if ($p eq $pat) { $ok = 1; last; }
    }
    next if $ok;
    print "UNMATCHED NAV: '$p' in $f\n";
    $bad++;
}
print scalar(@routes) . " routes defined, " . scalar(@navs) . " nav targets checked\n";
print $bad ? "ISSUES FOUND\n" : "OK: all nav targets match defined routes\n";
