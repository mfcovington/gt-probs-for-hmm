#!/usr/bin/env perl
# Mike Covington
# created: 2014-05-12
#
# Description:
#
use strict;
use warnings;
use Log::Reproducible;
use autodie;
use feature 'say';

my $gt_probs_file = $ARGV[0];
open my $gt_probs_fh, "<", $gt_probs_file;
my @header = split /\t/, <$gt_probs_fh>;
chomp @header;

for my $idx ( 2 .. $#header ) {
    my $sample = $header[$idx];
    open my $out_fh, ">", "$gt_probs_file.$sample";
    say $out_fh join "\t", $header[0], $header[1], $header[$idx];
    while (<$gt_probs_fh>) {
        chomp;
        my @line = split;
        say $out_fh join "\t", $line[0], $line[1], $line[$idx];
    }
    close $out_fh;
    seek $gt_probs_fh, 0, 0;
    <$gt_probs_fh>;
}
close $gt_probs_fh;
