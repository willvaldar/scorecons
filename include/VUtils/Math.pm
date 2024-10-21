package VUtils::Math;
use English;
use StdDefs;
use Assert;
use POSIX;
use strict;
use vars qw( @EXPORT_OK );
use base qw(Exporter);

require "dumpvar.pl";

use constant PI => 3.141592654;

@EXPORT_OK = qw(
    Avg
    Sqr
    Min
    Max
    ShannonStd
    Factorial
    LogBase
    ShannonAccurate
    MultinomialCoeff
    SterlingApprox
    IsInt
    IsEven
    IsNumber
    DegToRad
    RadToDeg
    Combinations
    SumNaturalNumbers
    Shannon
    
    avg
    );
#***********************************************************
# Implementation Globals
#

my %knownCombNR = ();

#***********************************************************
# Deprecated Methods
#

    sub avg{Avg(@ARG)}


#***********************************************************
# Interface Methods
#

sub Sqr        ($)    { $ARG[0] * $ARG[0] }
sub IsInt     ($)    { ceil($ARG[0]) == $ARG[0] ? true : false }    #almost 2x slower than calling modf
sub IsEven    ($)    { (modf($ARG[0]/2))[0] ? false : true }
sub IsNumber    ($)    { eval { $ARG[0]+=0 } == $ARG[0] }        #unavoidably prints to stdout
sub Min        ($$)    { $ARG[0] < $ARG[1] ? $ARG[0] : $ARG[1] }
sub Max        ($$)    { $ARG[0] > $ARG[1] ? $ARG[0] : $ARG[1] }
sub DegToRad    ($)    { $ARG[0] * PI / 180 }
sub RadToDeg    ($)    { $ARG[0] * 180 / PI }
sub SumNaturalNumbers($) { $ARG[0]*($ARG[0]+1)/2 }
    

    #***********************************************************
    # Avg
    #
    # Description:
    #
    #    gives the mean value of the elements in an array
    #
    # Input:
    #
    # (ra) array    = array of numbers
    #
    # Output:
    #
    # (real)    = mean
    #

    sub Avg ($)
    {
            my ($array) = @ARG;

            my $total = 0;
            my $denom = scalar(@$array);
            my $number;

            Assert( $denom != 0 , "Divide by zero error!\n");

            foreach $number (@$array)
            {
                    $total += $number;
            }
            return ($total / $denom);
    }


    #***********************************************************
    # Shannon Entropy
    #
    # Description:
    #
    #    measures variability of items in dataset
    #
    # Input:
    #
    # (ra)     aFreq     = array, each element of which is the
    #           frequency of items of type i
    # (int) nItems     = total number of items in dataset
    #
    # Output: 
    #
    # (real)    =  bits of information per item
    #
    # Notes:
    #       __ m
    # S = - \
    #       /      p(i) log p(i)
    #       -- i=1         2
    #
    # m = number of types
    # p(i) = fractional frequency of objects of type i
    #
    # Equivalent to (1/N)log(2)W, where N == nItems and W
    # is the MultinomialCoeff describing the number of
    # distinct ways N items falling into m categories
    # can be ordered. W is approximated for large N
    # using Sterling's Approximation in this case
    #

    sub ShannonStd ($$)
    {
        my ( $aFreq, $nItems ) = @ARG;

        my $freq;
        my $sum;

        $sum = 0;
        for $freq (@$aFreq)
        {
            if($freq > 0)    # 0ln0 == 1 for this function #
            {
                $sum += ( $freq / $nItems ) * log( $freq / $nItems );
            }
        }
        return ( -$sum / log(2) ) ;    # convert to log2 for 'information bits' #
    }

    #***********************************************************
    # Factorial
    #
    # Description:
    #
    #    n(n-1)(n-2)..(2)
    #
    # Input:
    #
    # (int)    number    = number to be 'factorialed'
    #
    # Output:
    #
    # (int)     = (number)!
    #


    sub Factorial ($)
    {
        my ($number) = @ARG;

        Assert( $number >= 0, "Invalid factorial: \'$number\'\n");

        my $i = $number - 1;

        while( $i > 1 )
        {
            $number *= $i;
            $i--;
        }
        return $number;
    }
    
    #***********************************************************
    # Combinations / Comb
    #
    # Description:
    #    evaluates the binomial coefficient
    #
    #           / n \
    #               |   |
    #                  \ r /  ,
    #
    #     i.e., the number of distinct subsets of size r from
    #    a set of size n.
    #
    #    Combinations(n,r) checks n and r are meaningful
    #    values, then calls the recursive function Comb(n,r)
    #
    # Input:
    #
    # (int) n = size of set
    #
    # (int) r = size of subset
    #
    # Output:
    #
    # (int)    nCr = n choose r
    #           
    # Comments:
    #
    # the number of combinations is calculated using the
    # recurrence relation :
    #  / n \     / n-1 \   / n-1 \ 
    #  |   |  =  |     | + |     |  
    #  \ r /     \  r  /   \ r-1 /
    # and is implemented using top-down dynamic programming,
    # storing all values of Comb(n,j) in a global array.
    #
 
    sub Combinations($$)
    {
        my ($n, $r) = @ARG;
        if($n < 0 
        or $r < 0
        or $r > $n
        or not (IsInt($r)&& IsInt($n)))
        {
            Fatal("Cannot compute $n choose $r\n");
        }
        return Comb($n, $r);
    }
    
    sub Comb($$)
    {
        my ($n, $r) = @ARG;
        if($knownCombNR{$n}{$r})
            {return $knownCombNR{$n}{$r}}
        if(0 == $r)
            {return 1}
        if($n == $r)
            {return 1}
        return $knownCombNR{$n}{$r} = Comb($n-1, $r) + Comb($n-1, $r-1);
    }

    #***********************************************************
    # LogBase
    #
    # Description:
    #
    #    gives log of number to specified base
    #
    # Input:
    #
    # (real)base    = base of desired log
    #
    # (real)number    = number to be logged
    #
    # Output:
    #
    # (real)    = log   (number)
    #             base
    #

    sub LogBase ($$)
    {
        my ( $base, $number ) = @ARG;

        return log($number) / log($base);
    }

    #***********************************************************
    # ShannonAccurate
    #
    # Description:
    #
    #    gives more accurate Shannon Entropy (see ShannonStd())
    #
    # Input:
    #
    # (ra)     aFreq     = array, each element of which is the
    #           frequency of items of type i
    # (int) nItems     = total number of items in dataset
    #
    # Output: 
    #
    # (real)    =  bits of information per item
    #

    sub ShannonAccurate ($$)
    {
        my ( $aFreq, $nItems ) = @ARG;

        my $W;

        $W = MultinomialCoeff( $aFreq, $nItems );

        return (1/$nItems)* LogBase( 2, $W );
    }

    #***********************************************************
    # MultinomialCoeff
    #
    # Description:
    #
    #    calculates number of ways nItems can be distinctly
    #    ordered when they fall into m types
    #
    # Input:
    #
    # (ra)     aFreq     = array, each element of which is the
    #           frequency of items of type i
    # (int) nItems     = total number of items in dataset
    #
    # Output:
    #
    # (int)        = number of distinct possible arrangements
    #           (ordered combinations)
    #
    # Notes:
    #
    # The number of distinct ways, W, you can order N objects 
    # when those objects fall into m types:
    #
    #           N!
    # W   =  --------
    #         m
    #        ___
    #        | |
    #        | | n(i)!
    #        - -
    #        i=1
    # 

    sub MultinomialCoeff ($$)
    {
        my ( $aFreq, $nItems ) = @ARG;

        my $product = 1;
        my $freq;

        for $freq ( @$aFreq )
        {
            if($freq > 0)
            {
                $product *= Factorial($freq);
            }
        }
        return Factorial($nItems) / $product;
    }
    
    #***********************************************************
    # SterlingApprox
    #
    # Description:
    #
    #    approximates ln(n!) for large n
    #
    # Input:
    #
    # (int)    number    = number to be factorialized
    #
    # Output: 
    #
    # (int)        = approximate ln(number!)
    #
    # Notes:
    #
    # Error of     10% for 1<N<10
    #        1% for 10<N<100
    #        0.1% for 100<N<1000
    #

    sub SterlingApprox ($)
    {
        my ( $number ) = @ARG;

        return $number * log($number) - $number;
    }
    
sub Shannon($)
{
    my $aFractionalFreqs = shift;
        
    my $sum = 0;
    for my $pi (@$aFractionalFreqs)
    {
        if ($pi > 0)
        {
            $sum += $pi * log $pi;
        }
    }
    return (-$sum/log(2));
}

true;
