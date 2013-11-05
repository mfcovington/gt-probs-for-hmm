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

my %snps;

open my $snp_fh, "<", "snp_master/polyDB.SL2.40ch01.nr";
<$snp_fh>;
while (<$snp_fh>) {
    my ( $chr, $pos ) = split;
    $snps{$chr}{$pos} = 1;
}
close $snp_fh;


open my $vcf_fh, "<", "2013-11-05/BIL.1000.vcf";#"BIL.01.vcf";
open my $out_fh, ">", "2013-11-05/out.vcf";#"out.vcf";
while (<$vcf_fh>) {
    next if /^##/;
    if (/^#/) {
        $_ =~ s|../bam/(BIL_\d+)_Slc.sorted.bam|$1|g;
        print $out_fh $_;
        next;
    }
    my ( $chr, $pos ) = split;
    print $out_fh $_ if exists $snps{$chr}{$pos};
}
close $out_fh;
close $vcf_fh;
