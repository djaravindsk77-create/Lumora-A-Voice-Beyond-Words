#!/usr/bin/perl
# 1) Verify every package:lumora/... import maps to an existing file.
# 2) Verify every l.t('...') / l.exists key used in UI exists in l10n maps.
use strict;
use warnings;
use File::Find;

my @files;
find(sub { push @files, $File::Find::name if /\.dart$/ && $File::Find::name !~ m{\btool\b} }, 'lib', 'test');

my $fail = 0;

# ---- package import resolution ----
for my $f (@files) {
    open my $fh, '<', $f or next;
    while (my $line = <$fh>) {
        if ($line =~ /import\s+['"]package:lumora\/([^'"]+)['"]/) {
            my $target = "lib/$1";
            unless (-f $target) {
                print "MISSING IMPORT TARGET: $f -> $1\n";
                $fail = 1;
            }
        }
    }
}

# ---- l10n key coverage ----
sub read_l10n_keys {
    my ($file) = @_;
    open my $fh, '<', $file or return;
    local $/;
    my $src = <$fh>;
    my %keys;
    while ($src =~ /'([a-zA-Z0-9_.]+)'\s*:/g) { $keys{$1} = 1; }
    return %keys;
}

my %en = read_l10n_keys('lib/core/localization/l10n_en.dart');
my %ta = read_l10n_keys('lib/core/localization/l10n_ta.dart');
print "EN keys: " . scalar(keys %en) . ", TA keys: " . scalar(keys %ta) . "\n";

# dynamic keys built with string interpolation are skipped; static ones checked.
my %used_static;
my %used_prefix;
for my $f (@files) {
    open my $fh, '<', $f or next;
    local $/;
    my $src = <$fh>;
    $src =~ s{//[^\n]*}{}g;
    # l.t('key')
    while ($src =~ /l\.t\('([a-zA-Z0-9_.]+)'\)/g) { $used_static{$1}{$f} = 1; }
    # context-based L10n keys via AppL10n? also "tr('key')" pattern if used
    while ($src =~ /\.t\('([a-zA-Z0-9_.]+)'\)/g) { $used_static{$1}{$f} = 1; }

}

for my $key (sort keys %used_static) {
    next if $key =~ /\$/;
    unless ($en{$key}) { print "MISSING EN KEY: $key (used in " . (keys %{ $used_static{$key} })[0] . ")\n"; $fail = 1; }
    unless ($ta{$key}) { print "MISSING TA KEY: $key\n"; $fail = 1; }
}

print $fail ? "FAILURES FOUND\n" : "OK: imports + l10n keys all resolve\n";
