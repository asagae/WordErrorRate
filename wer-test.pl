#!/usr/bin/perl 
#
# wer-test.pl: test file for WordErrorRate.pm perl module
#
# Copyright 2018,2018 Alicia Sagae
#
# WordErrorRate, tools for calculating word error rate between a hypothesis and reference text.
# Copyright 2017,2018 Alicia Sagae
# This file is part of WordErrorRate.
#
# WordErrorRate is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# WordErrorRate is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with WordErrorRater.  If not, see <http://www.gnu.org/licenses/>.#
#
#
use strict;
use Data::Dumper;

use WordErrorRate;


## Test instantiator
#
print "\nTesting instantiator\n";
my $wer = WordErrorRate->new();
print "Instantiated\n";

## Create some sample data
#
print "\nSample data:\n";
my $hyp = "This *noise* is a one two three four test! No kidding. YEAH.";
my $ref = "this is a 1 2 3 4 test no kidding yeah";
print "hyp: $hyp\n";
print "ref: $ref\n";


## Test clean and normalize_numbers
#
print "\nTesting clean\n";
$hyp = $wer->clean($hyp);
if ($hyp eq $ref){ print "Cleaned. hyp: $hyp\n"; }
else { print "FAIL. hyp is now: $hyp\n";
}


## Test distance 
#
print "\nTesting distance between matching strings\n";
my $distance_ref;
$distance_ref = $wer->distance($hyp, $ref);
if ( defined $distance_ref ){ print "Distance is defined\n"; }
my $I = scalar( split( /  */, $hyp) );
my $J = scalar( split( /  */, $ref) );
if (0 == $distance_ref->[$I][$J]){ 
	print "Distance is successful:";
	print "distance in cell $I, $J is $distance_ref->[$I][$J]\n";
}else{ print "Distance test FAILED: should be 0, found $distance_ref->[$I][$J]\n"; }

print "\nTesting non-matching distance\n";
$hyp = "no kidding";
$I = scalar( split( /  */, $hyp) );
print "hyp: $hyp\n";
print "ref: $ref\n";
$distance_ref = $wer->distance($hyp, $ref);
print "New distance: $distance_ref->[$I][$J]\n";
if (9 == $distance_ref->[$I][$J]){ 
	print "Distance is successful:";
	print "distance in cell $I, $J is $distance_ref->[$I][$J]\n";
}else{ print "Distance test FAILED: should be 9, found $distance_ref->[$I][$J]\n"; }
print "Distance matrix looks like this:\n";
print Dumper(\$distance_ref);


## Test align
#
print "\nTesting Alignment\n";
$hyp = "this is a";
$ref = "this is a";
$I = $J = 3;
my $alignment_ref = $wer->align($hyp, $ref);
if( defined $alignment_ref ){ print "Alignment is defined\n"; }
#print Dumper(\$alignment_ref);
print "Alignment of cell $I, $J";
print " is @{$alignment_ref->[$I][$J]}\n";

# Testing alignment of non-matching strings
print "\nAlignment of non-matching strings\n";
$hyp = "I'm not kidding";
$ref = "really not kidding";
$J = scalar( split( /  */, $ref) );
$I = scalar( split( /  */, $hyp) );
print "hyp: $hyp\n";
print "ref: $ref\n";
$alignment_ref = $wer->align($hyp, $ref);
#print Dumper(\$alignment_ref);
print "Alignment of cell $I, $J";
print " is @{$alignment_ref->[$I][$J]}\n";
if ( ($alignment_ref->[$I][$J]->[0] == 2) &&
	($alignment_ref->[$I][$J]->[1] == 2) ){
	print "Alignment Passed\n";
	}
	else{ print "FAIL: Alignment\n"; }


print "\nTesting Decode\n";
my $substitutions = $wer->decode($hyp, $ref, $alignment_ref);
print "Found substitutions:\n";
foreach my $elem ( @$substitutions ){ print "\t$elem\n"; }


# Testing decoding of longer strings
print "\nDecoding of longer strings\n";
$hyp = "I'm not kidding apple pie cherry tart yes yes yes";
$ref = "really not kidding cherry pie apple tart no no";
$J = scalar( split( /  */, $ref) );
$I = scalar( split( /  */, $hyp) );
print "hyp: $hyp\n";
print "ref: $ref\n";
$alignment_ref = $wer->align($hyp, $ref);
$substitutions = $wer->decode($hyp, $ref, $alignment_ref);
print "Found substitutions:\n";
foreach my $elem ( @$substitutions ){ print "\t$elem\n"; }

print "\n";








