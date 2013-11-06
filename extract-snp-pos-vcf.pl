#!/usr/bin/env perl
# Mike Covington
# created: 2013-10-31
#
# Description:
#
use strict;
use warnings;
use autodie;
use feature 'say';
use Array::Utils 'array_minus';

my $min_cov = 0;
my $min_gq  = 0;

my %snps;
my @parents = qw( M82 PEN );

open my $snp_fh, "<", "snp_master/polyDB.SL2.40ch01.nr";
<$snp_fh>;
while (<$snp_fh>) {
    my ( $chr, $pos, $ref, $alt, $alt_gt ) = split;
    my @alt_gt_ary = ($alt_gt);
    my ($ref_gt) = array_minus @parents, @alt_gt_ary;
    $snps{$chr}{$pos}{$ref} = $ref_gt;
    $snps{$chr}{$pos}{$alt} = $alt_gt;
}
close $snp_fh;

my $ncol;

open my $vcf_fh, "<", "2013-11-05/BIL.1000.vcf";#"BIL.01.vcf";
open my $out_fh, ">", "2013-11-05/out.vcf";#"out.vcf";
while (<$vcf_fh>) {
    next if /^##/;
    if (/^#/) {
        $_ =~ s|../bam/(BIL_\d+)_Slc.sorted.bam|$1|g;
        $ncol = scalar split;
        print $out_fh $_;
        next;
    }
    my ( $chr, $pos, $ref, $alt, @samples ) =
      (split)[ 0 .. 1, 3 .. 4, 9 .. $ncol - 1 ];

    next unless exists $snps{$chr}{$pos};

      # TODO: next if multiple alts

    my @processed;
    for my $sample (@samples) {
        my ( $gt, $pl, $dp, $gq ) = split /:/, $sample;

        if ( $dp < $min_cov || $gq < $min_gq ) {
            push @processed, "NA,NA,NA";
            next;
        }

    }

    print $out_fh $_ if exists $snps{$chr}{$pos};
}
close $out_fh;
close $vcf_fh;
