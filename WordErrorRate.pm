#!/usr/bin/perl
#
# WordErrorRate.pm
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
use List::Util qw[min max];
use Math::Round qw[nearest];
use Data::Dumper;

package WordErrorRate;

# Constructor
#
# Example: my $wer = new(WordErrorRate);
#
sub new
{
	my $class = shift;

	my $self = {};

	bless( $self, $class );

	return $self;
}



# distance
#
# Take two strings as arguments and find the lowest-cost alignment between them
# Return a reference to a 2-D array that contains costs. The cost of the 
# entire alignment is in cell (I, J) where I is the length of the hypothesis text
# and J is the length of the reference text. 
#
# Example: my $distance_ref = $wer->distance("this is a test", "this is not a test");
# if ($distance_ref->[4][5] == 1){ print "distance is correct\n"; }   
#
sub distance 
{
	my $self = shift;
	my $hyp = shift;
	my $ref = shift;

	my @distance_matrix = ();
	my @alignment_matrix = ();

	# initialize word arrays
        my @hyp = split( /  */, $hyp );
	my @ref = split( /  */, $ref );
	my $I = scalar(@hyp);
	my $J = scalar(@ref);

	# initialize the distance matrix
	$distance_matrix[0][0] = 0;
	for (my $i=0; $i<=$I; $i++){ 
		for (my $j=0; $j<=$J; $j++){
			if( $i==0 ){
				$distance_matrix[0][$j] = $j;
			}
			elsif( $j==0 ){
				$distance_matrix[$i][0] = $i;
			}
		}
	}
	
	# complete the distance matrix
	for (my $i=1; $i<=$I; $i++){ 
		for (my $j=1; $j<=$J; $j++){

			if( $hyp[$i-1] eq $ref[$j-1] ){ 
				$distance_matrix[$i][$j] = 
					$distance_matrix[$i-1][$j-1];
			}
			else{
				my $substitution = $distance_matrix[$i-1][$j-1] + 1;
				my $insertion = $distance_matrix[$i][$j-1] + 1;
				my $deletion = $distance_matrix[$i-1][$j] + 1;
				my $cost = List::Util::min($substitution, $insertion, $deletion);
				$distance_matrix[$i][$j] = $cost;
			}
		}
	}
	return \@distance_matrix;
}


# align
#
# Take two strings as arguments and find the lowest-cost alignment between them
# Return a reference to a 2-D array that contains alignments
#
# Example: my $alignment_ref = $wer->align("this is a test", "this is not a test");
# if (@{$alignment_ref->[4][5]} == (3, 4)){ print "alignment is correct\n"; }  
#
sub align 
{
	my $self = shift;
	my $hyp = shift;
	my $ref = shift;

	my @distance_matrix = ();
	my @alignment_matrix = ();

	# initialize word arrays
        my @hyp = split( /  */, $hyp );
	my @ref = split( /  */, $ref );
	my $I = scalar(@hyp);
	my $J = scalar(@ref);

	# initialize the distance matrix
	$distance_matrix[0][0] = 0;
	for (my $i=0; $i<=$I; $i++){ 
		for (my $j=0; $j<=$J; $j++){
			if( $i==0 ){
				$distance_matrix[0][$j] = $j;
			}
			elsif( $j==0 ){
				$distance_matrix[$i][0] = $i;
			}
		}
	}
	#print Data::Dumper->Dump( \@alignment_matrix );
	
	# complete the distance matrix
	for (my $i=1; $i<=$I; $i++){ 
		for (my $j=1; $j<=$J; $j++){

			if( $hyp[$i-1] eq $ref[$j-1] ){ 
				$distance_matrix[$i][$j] = 
					$distance_matrix[$i-1][$j-1];
				$alignment_matrix[$i][$j] = [$i-1, $j-1];
			}
			else{
				my $substitution = $distance_matrix[$i-1][$j-1] + 1;
				my $insertion = $distance_matrix[$i][$j-1] + 1;
				my $deletion = $distance_matrix[$i-1][$j] + 1;
				my $cost = List::Util::min($substitution, $insertion, $deletion);
				$distance_matrix[$i][$j] = $cost;

				# The values in the alignment matrix are back-pointers
				# to the lowest-cost predecessor.
				# If word i in the hypothesis is aligned to word j in 
				# the reference, then the predecessor is given by
				# $alignment_matrix[$i][$j]->[0] in the hypothesis, aligned
				# to word $alignment_matrix[$i][$j]->[1] in the reference
				#
				if( $substitution == $cost ){
					$alignment_matrix[$i][$j] = [$i-1, $j-1];
				}elsif( $insertion == $cost ){
					$alignment_matrix[$i][$j] = [$i, $j-1];
				}else{
					$alignment_matrix[$i][$j] = [$i-1, $j];
				}
			}
		}
	}
	return \@alignment_matrix;
}


# decode
#
# Read an alignment matrix and print the substitutions; every cell where the 
# predecessor is ($i-1, $j-1) and the tokens in reference and hyp do not match.
#
# Example: 
# my $alignment_ref = $wer->align("this is a test", "this is the best");
# my $substitution_array_ref = $wer->decode($hyp, $ref, $alignment_ref);
# foreach my $elem ( @$substitution_array_ref ){ print "$elem\n"; } 
#
# Result: 
# a=the
# test=best
#
sub decode
{
	my $self = shift;
	my $hyp = shift;
	my $ref = shift;
	my $alignment_ref = shift;

	my @substitutions = ();
	my @i_terms = split( /  */, $hyp );
	my $I = scalar @i_terms;
	my @j_terms = split( /  */, $ref );
	my $J = scalar @j_terms;

	unless( defined( $alignment_ref->[$I][$J] ) ){ 
		print "WARNING: alignment does not match hyp, ref\n";
		return 0;
	}

	my $i=$I;
	my $j=$J;
	my $prev_i = $alignment_ref->[$i][$j]->[0];
	my $prev_j = $alignment_ref->[$i][$j]->[1];
	while( ( $i > 0 ) or ( $j > 0 ) ){

		if( ($prev_i == $i-1) && ($prev_j == $j-1) ){
			unless( $i_terms[$i-1] eq $j_terms[$j-1] ){
				push( @substitutions, "$i_terms[$i-1]=$j_terms[$j-1]" );
			}
		}	
		$i = $prev_i;
		$j = $prev_j;	
		$prev_i = $alignment_ref->[$i][$j]->[0];
		$prev_j = $alignment_ref->[$i][$j]->[1];
	}
	return \@substitutions;
}


# clean
#
# Take a string and return a cleaned version: remove punctuation, multiple spaces, other markup
# Return the clean string
#
# Example: my $clean_hyp = $wer->clean( $hyp );
#
sub clean
{
	my $self = shift;
	my $hyp = shift;
	chomp( $hyp );
	
	# Remove windows carriage returns, if present
	$hyp =~ tr/\015//d; 

	# Remove annotator's markup
	$hyp =~ s/\*[^\*]+\*//g;
	$hyp =~ tr/[A-Z]/[a-z]/;
	$hyp =~ s/[\,\.\;\:\?\!\*\_\-\(\)]//g;
	$hyp =~ s/  */ /g;
	$hyp = $self->normalize_numbers($hyp);

	return $hyp;
}


# normalize_numbers
#
# Normalize number words and digits for the purpose
# of string matching. Right now we convert to digits;
# This will only work for small numbers, there is no
# easy solution for numbers in general.
#
# Example: my $normalized_string = $wer->normalize_numbers("one two three four five");
#
sub normalize_numbers{


	my $self = shift;
	my $hyp = shift;
	$hyp =~ s/zero/0/g;
	$hyp =~ s/one/1/g;
	$hyp =~ s/two/2/g;
	$hyp =~ s/three/3/g;
	$hyp =~ s/four/4/g;
	$hyp =~ s/five/5/g;
	$hyp =~ s/six/6/g;
	$hyp =~ s/seven/7/g;
	$hyp =~ s/eight/8/g;
	$hyp =~ s/nine/9/g;
	$hyp =~ s/ten/10/g;
	return $hyp;
}


1; # Class file must return a true value
