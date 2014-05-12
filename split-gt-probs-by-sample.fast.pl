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

my %samples;
for my $index ( 2 .. $#header ) {
    my $sample_id = $header[$index];
    open $samples{$index}{fh}, ">", "$gt_probs_file.TEST.$sample_id";
    say { $samples{$index}{fh} } join "\t", $header[0], $header[1],
        $sample_id;
}

while (<$gt_probs_fh>) {
    chomp;
    my @line = split;

    for my $index ( keys %samples ) {
        say { $samples{$index}{fh} } join "\t", $line[0], $line[1],
            $line[$index];
    }
}
close $gt_probs_fh;
close $samples{$_}{fh} for keys %samples;
