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
use List::Util 'sum';

my ( $vcf_file, $out_file, @snp_files ) = @ARGV;

my $alternative_lh_calc = 1;
my $min_cov = 1;
my $min_gq  = 0;

my %snps;
my $par1    = 'M82';
my $par2    = 'PEN';
my @parents = ( $par1, $par2 );

for my $file (@snp_files) {
    open my $snp_fh, "<", $file;
    <$snp_fh>;
    while (<$snp_fh>) {
        my ( $chr, $pos, $ref, $alt, $alt_gt ) = split;
        my @alt_gt_ary = ($alt_gt);
        my ($ref_gt) = array_minus @parents, @alt_gt_ary;
        $snps{$chr}{$pos}{$ref} = $ref_gt;
        $snps{$chr}{$pos}{$alt} = $alt_gt;
    }
    close $snp_fh;
}

my $ncol;

open my $vcf_fh, "<", $vcf_file;
open my $out_fh, ">", $out_file;
while (<$vcf_fh>) {
    next if /^##/;
    if (/^#/) {
        chomp;
        $_ =~ s|../bam/(BIL_\d+)_Slc.sorted.bam|$1|g;
        $ncol = scalar split;
        my @sample_ids = (split)[ 9 .. $ncol - 1 ];
        say $out_fh join "\t", 'chr', 'pos', @sample_ids;
        next;
    }
    my ( $chr, $pos, $ref, $alt, @samples ) =
      (split)[ 0 .. 1, 3 .. 4, 9 .. $ncol - 1 ];

    next unless exists $snps{$chr}{$pos};

    # Skip INDELS and multiple alts
    next unless length "$ref$alt" == 2;

    # Skip if primary alt allele in VCF file differs from alt allele in SNP file
    next unless exists $snps{$chr}{$pos}{$alt};

    my @processed;
    for my $sample (@samples) {
        my ( $gt, $pl, $dp, $gq ) = split /:/, $sample;

        if ( $dp < $min_cov || $gq < $min_gq ) {
            push @processed, "NA,NA,NA";
            next;
        }

        my @likelihoods_phred = split /,/, $pl;
        my ( $ref_lh, $het_lh, $alt_lh )
            = map { 10**-( $_ / 10 ) } @likelihoods_phred;
        $het_lh /= 16 if $alternative_lh_calc;
        $ref_lh *= ( 1 - ( 1 / 16 ) ) / 2 if $alternative_lh_calc;
        $alt_lh *= ( 1 - ( 1 / 16 ) ) / 2 if $alternative_lh_calc;
        my $sum_lhs = sum $ref_lh, $het_lh, $alt_lh;

        my @gt_probs = map { $_ / $sum_lhs } $ref_lh, $het_lh, $alt_lh;
        @gt_probs = reverse @gt_probs if $snps{$chr}{$pos}{$alt} eq $par1;
        push @processed, join ",", @gt_probs;
    }

    say $out_fh join "\t", $chr, $pos, @processed;
}
close $out_fh;
close $vcf_fh;
