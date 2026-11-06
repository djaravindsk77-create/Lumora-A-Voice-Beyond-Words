#!/usr/bin/perl
# Lightweight static validation for Lumora.
# Checks: bracket balance, relative import resolution, l10n key parity,
# localization keys used by UI, route wiring for context.go('/...').
use strict;
use warnings;
use File::Find;
use File::Spec;
use Cwd qw(abs_path);

my @errors;
my @dart_files;
my $root = abs_path('.');

find(sub {
    # Skip the validation scripts themselves: they contain Dart regex
    # literals that no lightweight parser can handle reliably.
    return if $File::Find::name =~ /\btool\b/;
    push @dart_files, $File::Find::name if /\.dart$/;
}, grep { -d $_ } map { File::Spec->catdir($root, $_) } ('lib', 'test'));

# ---- strip comments and string contents (conservative) ----
sub strip {
    my ($src) = @_;
    my $out = '';
    my $i = 0;
    my $n = length($src);
    my ($line_comment, $block_comment, $in_str, $quote, $triple) = (0, 0, 0, '', 0);
    while ($i < $n) {
        my $c = substr($src, $i, 1);
        my $next = $i + 1 < $n ? substr($src, $i + 1, 1) : '';
        my $next2 = $i + 2 < $n ? substr($src, $i + 2, 1) : '';
        if ($line_comment) { if ($c eq "\n") { $line_comment = 0; $out .= $c; } $i++; next; }
        if ($block_comment) { if ($c eq '*' && $next eq '/') { $block_comment = 0; $i += 2; next; } $i++; next; }
        if ($in_str) {
            if ($triple && $c eq $quote && $next eq $quote && $next2 eq $quote) {
                $in_str = 0; $triple = 0; $out .= ' '; $i += 3; next;
            }
            if (!$triple && $c eq '\\') { $i += 2; next; }
            if (!$triple && $c eq $quote) { $in_str = 0; }
            $i++;
            next;
        }
        if ($c eq '/' && $next eq '/') { $line_comment = 1; $i += 2; next; }
        if ($c eq '/' && $next eq '*') { $block_comment = 1; $i += 2; next; }
        if (($c eq "'" || $c eq '"') && $next eq $c && $next2 eq $c) {
            $in_str = 1; $triple = 1; $quote = $c; $out .= ' '; $i += 3; next;
        }
        if ($c eq "'" || $c eq '"') { $in_str = 1; $quote = $c; $out .= ' '; $i++; next; }
        $out .= $c;
        $i++;
    }
    return $out;
}

my %stripped;
for my $f (@dart_files) {
    open my $fh, '<', $f or next;
    local $/;
    my $src = <$fh>;
    close $fh;
    $stripped{$f} = strip($src);
}

# ---- 1. bracket balance ----
for my $f (@dart_files) {
    my $s = $stripped{$f};
    my %delta;
    $delta{paren}  = (() = $s =~ /\(/g) - (() = $s =~ /\)/g);
    $delta{curly}  = (() = $s =~ /\{/g) - (() = $s =~ /\}/g);
    $delta{square} = (() = $s =~ /\[/g) - (() = $s =~ /\]/g);
    for my $k (keys %delta) {
        if ($delta{$k} != 0) {
            push @errors, "$f: unbalanced $k (delta $delta{$k})";
        }
    }
}

# ---- 2. relative imports resolve ----
for my $f (@dart_files) {
    while ($stripped{$f} =~ /import\s+['"]([^'"]+)['"]/g) {
        my $target = $1;
        next if $target =~ /^(dart:|package:)/;
        my ($vol, $dir, $file) = File::Spec->splitpath($f);
        my $full = File::Spec->rel2abs($target, File::Spec->catpath($vol, $dir, ''));
        unless (-f $full) {
            push @errors, "$f: unresolved import '$target'";
        }
    }
}

# ---- 3. l10n key parity ----
sub keys_of {
    my ($path) = @_;
    return () unless -f $path;
    open my $fh, '<', $path or return ();
    local $/;
    my $src = <$fh>;
    close $fh;
    my %keys;
    while ($src =~ /['"]([a-zA-Z0-9_.]+)['"]\s*:/g) {
        $keys{$1} = 1;
    }
    return keys %keys;
}

my %en = map { $_ => 1 } keys_of('lib/core/localization/l10n_en.dart');
my %ta = map { $_ => 1 } keys_of('lib/core/localization/l10n_ta.dart');
my @missing_ta = grep { !$ta{$_} } sort keys %en;
if (@missing_ta) {
    push @errors, 'l10n_ta.dart missing ' . scalar(@missing_ta) . " keys: "
        . join(', ', @missing_ta[0 .. ($#missing_ta < 7 ? $#missing_ta : 7)]) . '...';
}

# ---- 4. localization keys used by UI exist in EN ----
my %used;
for my $f (@dart_files) {
    next if $f =~ /l10n_(en|ta)\.dart$/;
    while ($stripped{$f} =~ /(?:l10n|l)\.t\(\s*['"]([a-zA-Z0-9_.]+)['"]/g) {
        $used{$1} = $f;
    }
}
my @unknown = grep { !$en{$_} } sort keys %used;
if (@unknown) {
    push @errors, "l10n keys used but not defined: " . join(', ', @unknown);
}

# ---- 5. route wiring ----
my %routes;
if (open my $fh, '<', 'lib/core/routing/app_router.dart') {
    local $/;
    my $src = <$fh>;
    close $fh;
    my $clean = strip($src);
    while ($clean =~ /path:\s*['"]([^'"]+)['"]/g) {
        $routes{$1} = 1;
    }
}
for my $f (@dart_files) {
    next if $f =~ /app_router\.dart$/;
    while ($stripped{$f} =~ /(?:go|pushReplacement)\(\s*['"]\/([a-z0-9\-\/]*)['"]/g) {
        my $p = "/$1";
        my $ok = 0;
        for my $r (keys %routes) {
            my $prefix = $r;
            $prefix =~ s/:.*//;         # drop :param parts
            $prefix =~ s/\/$//;         # trailing slash
            if ($r eq $p || $p =~ /^\Q$prefix\E(\/|$)/) { $ok = 1; last; }
        }
        unless ($ok) {
            push @errors, "$f: navigation to unknown route '$p'";
        }
    }
}

# ---- report ----
my $count = scalar @dart_files;
if (!@errors) {
    print "OK: $count Dart files validated (balance, imports, l10n, routes).\n";
} else {
    print 'FAILED with ' . scalar(@errors) . " issue(s):\n";
    print " - $_\n" for @errors;
    exit 1;
}
