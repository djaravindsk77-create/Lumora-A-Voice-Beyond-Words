#!/usr/bin/env perl
# Lumora siren — PCM 16-bit mono, 22050 Hz, 4 sweeping cycles.
# Builds a completely fresh WAV every run, no partial-file leftovers.
use strict;
use warnings;
use constant RATE => 22050;
use constant SECONDS => 2.6;
use constant CHANNELS => 1;
use constant BITS => 16;

my $samples = int(RATE * SECONDS);
my $bps = BITS / 8;
my $data_bytes = $samples * CHANNELS * $bps;          # must equal samples*2
my $riff_size = 36 + $data_bytes;                     # everything after byte 8
my $out = 'assets/audio/siren.wav';

unlink $out if -e $out;
open my $fh, '>:raw', $out or die "cannot write $out: $!";

# RIFF header: "RIFF" <riff_size> "WAVE"
print $fh pack('a4 V a4', 'RIFF', $riff_size, 'WAVE');
# fmt  chunk: 16 bytes, PCM, 1 ch, RATE, byteRate, blockAlign, BITS
print $fh pack('a4 V V v V v v v',
    'fmt ', 16,           # chunk size
    1,                    # wFormatTag PCM
    CHANNELS,             # nChannels
    RATE,                 # nSamplesPerSec
    RATE * CHANNELS * $bps, # nAvgBytesPerSec
    CHANNELS * $bps,         # nBlockAlign
    BITS,                 # wBitsPerSample
);
# data chunk: "data" <data_bytes>
print $fh pack('a4 V', 'data', $data_bytes);

for (my $i = 0; $i < $samples; $i++) {
    my $t = $i / RATE;
    my $cycle = int($t / 0.65);
    my $phase = ($t - $cycle * 0.65) / 0.65;
    my $freq = 350 + 550 * (0.5 - 0.5 * cos(2 * 3.1415926535 * $phase));
    my $sample = 0.65 * sin(2 * 3.1415926535 * $freq * $t);
    my $s16 = int($sample * 32767);
    print $fh pack('s*', $s16);
}
close $fh or die "close failed: $!";

printf "siren rebuilt: samples=%d data_bytes=%d riff_size=%d file_bytes=%d\n",
    $samples, $data_bytes, $riff_size, 44 + $data_bytes;
