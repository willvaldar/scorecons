package VUtils::DataManip;
use English;
use Assert;
use StdDefs;
use Algorithm qw(Transform);
use VUtils::Math qw(IsInt);
use VarType qw(IsArrayRef IsHashRef);
use strict;
use POSIX;
use Nr;
use vars qw( @EXPORT_OK );

use base qw(Exporter);
@EXPORT_OK = qw(
    GroupElements
    HashElementFrequencies
    ListElementFrequencies
    HashOneToOne
    HashMatrix2D
    HashOneToMany
    InvertHash
    InvertOneToManyHash
    HashBoolean
    HashAllAgainstValue
    UniqueElements
    ArrayMin
    ArrayMax
    ArrayRange
    Array2DRange
    Hash2DRange
    Array2DCopy
    Hash2DCopy
    Array2DBlock
    Array3DBlock
    Array2DSwapAxes
    ArrayDiff
    ArrayCommon
    MakePhysicalHistogram
    MakeHistogram
    SortParalellArrays_Num
    SortParalellArrays_String
    TraverseHashTree
    NewArray
    BarChart
    ArrayLTransformToRange
    SetEquals
    ArrayMean
    ArraySum
    UniqueSets
    HashAgainstIndices
    SetIntersect
    Array2DFlatten
    BinDatum
    ElementRanks
    ElementFranks
    TransformArrayToHash
    ArrayAdd
    ArrayResize
    );

sub Array2DBlock ($$$$$);
sub Array2DCopy ($);
sub Array2DFlatten($);
sub Array2DRange ($);
sub Array2DSwapAxes ($);
sub Array3DBlock ($$$$$$$);
sub ArrayAdd($$$);
sub ArrayCommon ($);
sub ArrayDiff ($$);
sub ArrayLTransformToRange($$$$$);
sub ArrayMax ($);
sub ArrayMean($);
sub ArrayMin ($);
sub ArrayRange ($);
sub ArrayResize($$);
sub ArraySum($);
sub BarChart ($$$);
sub BinDatum($$$$$);
sub ElementFranks($$);
sub ElementRanks($$);
sub GroupElements ($$);
sub Hash2DCopy ($);
sub Hash2DRange ($);
sub HashAgainstIndices($);
sub HashAllAgainstValue ($$);
sub HashBoolean ($);
sub HashElementFrequencies ($);
sub HashMatrix2D ($$$);
sub HashOneToMany ($$);
sub HashOneToOne ($$);
sub InvertHash ($);
sub InvertOneToManyHash ($);
sub ListElementFrequencies ($);
sub MakeHistogram;
sub MakePhysicalHistogram;
sub NewArray;
sub SetEquals($$);
sub SetIntersect($);
sub SortParalellArrays_Num;
sub SortParalellArrays_String;
sub TransformArrayToHash; # ($$) or ($$$)
sub TraverseHashTree ($$);
sub UniqueElements ($); 
sub UniqueSets($);

#***********************************************************
# GroupElements
#
# Description:
#
#    reduces the heterogeneity of an array, converting
#    each element to a value representing its group
#
# Input:
#
# (ra) aRaw     = array of raw population
#
# (rh) hGrouping = many to few mapping that converts
#           datum x -> member of group A
#
# Output:
#
# (ra)         = less heterogenous array
#

sub GroupElements ($$)
{
    my ( $aRaw, $hGroupings ) = @ARG;
    my $aGrouped = [];
    my $elem;

    for $elem ( @$aRaw )
    {
        Assert( exists( $hGroupings->{$elem} ), "$elem has no defined group\n" );
        push @$aGrouped, $hGroupings->{$elem};
    }
    return $aGrouped;
}

#***********************************************************
# HashElementFrequencies
#
# Description:
#
#    make a hash of: item against how it
#    appears
#
# Input:
#
# (ra) array    = array of items
#
# Output:
#
# (rh) hFreq    = hash of item -> frequency
#

sub HashElementFrequencies ($)
{
    my ($array) = @ARG;
    my $hFreq = {};
    my $elem;

    for $elem ( @$array )
    {
        if( not exists($hFreq->{$elem}) )
        {
            $hFreq->{$elem} = 1;
        }
        else
        {
            $hFreq->{$elem}++;
        }
    }
    return $hFreq;
}

#***********************************************************
# ListElementFrequencies
# 
# Description:
# 
#     make a list of frequencies of element types
#     
# Input:
# 
# (ra) array    = array of items
# 
# Output:
# 
# (ra) array    = array of frequencies
# 
# Notes:
# 
# see HashElementFrequencies
# 

sub ListElementFrequencies ($)
{
    my ($array) = @ARG;

    return [ values %{ HashElementFrequencies($array) } ];
}

#***********************************************************
# HashOneToOne
# 
# Description:
# 
#     make a hashtable from an array of keys that is
#     non-redundant and an array of associated values
# 
# Input:
# 
# (ra) aKeys    = array, elements of which are to be used as
#           keys
# 
# (ra) aValues    = array, elements of which are to be used as
#           values
# 
# Output:
# 
# (rh)        = hash of key -> value
# 
# Notes:
# 
# aKeys must map exactly onto aValues. aKeys must be
# non-redundant.
# 

sub HashOneToOne ($$)
{
    my ($aKeys, $aValues) = @ARG;
    my $hash;
    @$hash{@$aKeys} = @$aValues;
    return $hash;
}

sub HashMatrix2D ($$$)
{
    my ($array2d, $aKeys_i, $aKeys_j) = @ARG;
    my $hMatrix = {};

    my $iSize;
    my $jSize;
    
    $iSize = scalar( @$array2d );
    $jSize = scalar( @{ $array2d->[0] } );
    
    my $i;
    my $j;
    my $iName;
    my $jName;
    my $value;
    
    for($i=0; $i < $iSize; $i++){
    for($j=0; $j < $jSize; $j++)
    {
        $iName = $aKeys_i->[$i];
        $jName = $aKeys_j->[$j];
        $value = $array2d->[$i][$j];
        
        $hMatrix->{$iName}{$jName} = $value;
    }}
    return $hMatrix;
}


#***********************************************************
# HashOneToMany
# 
# Description:
# 
#     make a hash table of arrays from an array of keys
#     that is redundant and an associated array of values
#    that may be redundant
# 
# Input:
# 
# (ra) aKeys    = redundant array of keys
# 
# (ra) aValues    = array of associated values
# 
# Output:
# 
# (rh)        = hash of key -> array of values
# 
# Note:
#
# the arrays for each key retain any redundancy, e.g.,
# smith -> john, cyril, john
# 
# Eliminate redundancy with UniqueElements() func, or
# use an hash of hash in the first place
#

sub HashOneToMany ($$)
{
    my ($aKeys, $aValues) = @ARG;

    Prefer( @$aKeys == @$aValues, "Different length arrays!" );

    my $hashOfArrays = {};
    my $i;
    my $key;
    my $value;

    for( $i=0; $i < scalar(@$aKeys); $i++ )
    {
        $key = $aKeys->[$i];
        $value = $aValues->[$i];

        if(not exists( $hashOfArrays->{$key} ) )
        {
            $hashOfArrays->{$key} = [ $value ];
        }
        else
        {
            push @{ $hashOfArrays->{$key} }, $value;
        }
    }
    return $hashOfArrays;
}

#***********************************************************
# HashBoolean
# 
# Description:
# 
#     make look up table of values against whether they
#     are present or not in the argument array
#     (i.e., against boolean values).
#     
# Input:
# 
# (ra) array    = array of items
# 
# Output:
# 
# (rh)        = hash of element -> true
#     
# Notes:
# 
# Useful for 'isa' type look-ups. E.g., if($isAminoAcid->{$i})    
#     

sub HashBoolean ($)
{
    my ($array) = @ARG;

    return HashAllAgainstValue( $array, true );
}

sub HashAllAgainstValue ($$)
{
    my ($array, $value) = @ARG;
    my $hash = {};
    my $elem;

    for $elem (@$array)
    {
        $hash->{ $elem } = $value;
    }
    return $hash;
}
    

#***********************************************************
# UniqueElements
# 
# Description:
# 
#     returns the unique elements in a list
#     
# Input:
# 
# (ra) array    = array that may be redundant
# 
# Output:
# 
# (ra)        = non-redundant array
# 
# Notes:
# 
# return array will be in a different order
# 

sub UniqueElements ($)
{
    my ($array) = @ARG;

    my %seen;

    @seen{@$array} = ();

    return [keys %seen];
}

#***********************************************************
# InvertHash
# 
# Description:
# 
#     makes hash of b -> a from hash of a -> b
# 
# Input:
# 
# (rh) hOriginal    = hash
#
# Output:
# 
# (rh) hInverted    = inverted hash (keys and values swapped)
# 
# Notes:
# 
# data will be lost if values are redundant
# 

sub InvertHash ($)
{
    my ($hOriginal) = @ARG;

    my $hInverted;

    %{$hInverted} = reverse %$hOriginal;

     return $hInverted;
}

#***********************************************************
# InvertOneToManyHash
# 
# Description:
# 
#     invert one-to-many hash without losing redundancy
#     e.g.,
#         smith -> john, cyril, tony, tony
#         blair -> tony, lionel, john
#     to
#         john -> smith, blair
#         cyril -> smith
#         tony -> smith, smith, blair
#         lional -> blair
# 
# Input:
# 
# (rh) hOriginal    = hash of arrays
# 
# Output:
# 
# (rh) hInverted    = hash of arrays (inverted)
# 
# Notes:
# 
# because an hash of *arrays* is used, each array may have
# some further redundancy, e.g., in the example above,
# there are two tony smiths. To eliminate this redundancy, use
# an hash of hashes
# 

sub InvertOneToManyHash ($)
{
    my ($hOriginal) = @ARG;

    my $hInverted = {};
    my $key;
    my $aValues;
    my $value;

    while( ($key, $aValues) =  each %$hOriginal)
    {
        for $value (@$aValues)
        {
            if( not exists($hInverted->{$value}) )
            {
                $hInverted->{$value} = [ $key ];
            }
            else
            {
                push @{ $hInverted->{$value} }, $key;
            }
        }
    }
    return $hInverted;
}

#***********************************************************
# ArrayMin
# 
# Description:
# 
#     find minimum value in array
# 
# Input:
# 
# (ra) array    = array of numbers
# 
# Output:
# 
# (real)        = minimum value
# 
# Notes:
# 
# to get both min and max it may be slightly faster to use
# ArrayRange()
# 

sub ArrayMin ($)
{
    my ($array) = @ARG;

    my $elem;
    my $min;
    my $firstIteration = true;

    for $elem (@$array)
    {
        if($firstIteration)
        {
            $min = $elem;
            $firstIteration = false;
        }
        elsif($elem < $min)
        {
            $min = $elem;
        }
    }
    return $min;
}

#***********************************************************
# ArrayMax
# 
# Description:
# 
#     find maximum value in array
# 
# Input:
# 
# (ra) array    = array of numbers
# 
# Output:
# 
# (real) max    = maximum value
# 
# Notes:
# 
# to get both min and max it may be slightly faster to use
# ArrayRange()
# 

sub ArrayMax ($)
{
    my ($array) = @ARG;

    my $elem;
    my $max;
    my $firstIteration = true;

    for $elem (@$array)
    {
        if($firstIteration)
        {
            $max = $elem;
            $firstIteration = false;
        }
        elsif($elem > $max)
        {
            $max = $elem;
        }
    }
    return $max;
}

#***********************************************************
# ArrayRange
# 
# Description:
# 
#     finds the range of an array, and gives the min
#     and max
#     
# Input:
# 
# (ra) array    = array of items
# 
# Output:
# 
# (real) range    = | min - max |
# 
# (real) min    = minumum value of array
# 
# (real) max    = maximum value of array
# 
# Notes:
# 
# This is faster that calling Max and Min together
# 

sub ArrayRange ($)
{
    my ($array) = @ARG;

    my $max;
    my $min;
    my $firstIteration = true;

    for my $elem (@$array)
    {
        if($firstIteration)
        {
            $max = $elem;
            $min = $elem;
            $firstIteration = false;
        }
        elsif($elem < $min)
        {
            $min = $elem;
        }
        elsif($elem > $max)
        {
            $max = $elem;
        }
    }
    my $range = abs( $max - $min );

    return wantarray ?
        ($range, $min, $max):
        $range;
}

sub Array2DRange ($)
{
    my ($array2d) = @ARG;

    my $min;
    my $max;
    my $range;

    my $row;
    my $elem;
    my $firstIteration = true;

    for $row (@$array2d)
    {
        for $elem (@$row)
        {
            if($firstIteration)
            {
                $max = $elem;
                $min = $elem;
                $firstIteration = false;
            }
            elsif($elem < $min)
            {
                $min = $elem;
            }
            elsif($elem > $max)
            {
                $max = $elem;
            }
        }
    }
    $range = abs( $max - $min );

    return wantarray ?
        ($range, $min, $max) :
        $range;
}

sub Hash2DRange ($)
{
    my ($hash2d) = @ARG;

    my $min;
    my $max;
    my $range;

    my $i;
    my $inode;
    my $j;
    my $value;
    my $firstIteration = true;

    while(($i, $inode)=each %$hash2d){
    while(($j, $value)=each %$inode)
    {
        if($firstIteration)
        {
            $max = $value;
            $min = $value;
            $firstIteration = false;
        }
        elsif($value < $min)
        {
            $min = $value;
        }
        elsif($value > $max)
        {
            $max = $value;
        }
    }}
    
    $range = abs( $max - $min );

    return wantarray ?
        ($range, $min, $max) :
        $range;
}

sub Array2DCopy ($)
{
    my ($array2d) = @ARG;

    my $array2d_copy = [];
    my $row;

    for $row (@$array2d)
    {
        push @$array2d_copy, [ @$row ];
    }
    return $array2d_copy;
}

sub Hash2DCopy ($)
{
    my ($hash2d) = @ARG;
    
    my $hash2d_copy = {};
    my $key;
    my $hValue;

    while( ($key, $hValue) =  each %$hash2d)
    {
        $hash2d_copy->{$key} = { %$hValue };
    }
    return $hash2d_copy;
}


sub Array2DBlock ($$$$$)
{
    my ($array2d, $x, $y, $dx, $dy) = @ARG;

    my $aBlock = [];
    my $i;
    my $j;
    my $elem;
    my $nXElems;
    my $nYElems;

    $nXElems = scalar( @$array2d );
    $nYElems = scalar( @{ $array2d->[0]} );

    Assert( $nXElems >= ($x + $dx), "Block is out of 2D array x bounds");
    Assert( $nYElems >= ($y + $dy), "Block is out of 2D array y bounds");

    for( $i = 0; $i < $dx; $i++ ){
    for( $j = 0; $j < $dy; $j++)
    {
        $elem = $array2d->[ ( $i + $x ) ][ ( $j + $y ) ];
        
        $aBlock->[$i][$j] = $elem;
    }}
    
    return $aBlock;
}


sub Array3DBlock ($$$$$$$)
{
    my ($array3d, $x, $y, $z, $dx, $dy, $dz) = @ARG;
    
    my $aBlock = [];
    my ($i, $j, $k);
    my $elem;
    my $nXElems;
    my $nYElems;
    my $nZElems;

    $nXElems = scalar( @$array3d );
    $nYElems = scalar( @{$array3d->[0]} );
    $nZElems = scalar( @{$array3d->[0][0]} );
    
    Assert( $nXElems >= ($x + $dx), "Block is out of 3D array x bounds");
    Assert( $nYElems >= ($y + $dy), "Block is out of 3D array y bounds");
    Assert( $nYElems >= ($y + $dy), "Block is out of 3D array z bounds");
    
    for( $i = 0; $i < $dx; $i++){
    for( $j = 0; $j < $dy; $j++){
    for( $k = 0; $k < $dz; $k++)
    {
        $elem = $array3d->[ ( $i + $x ) ][ ( $j + $y ) ][ ( $k + $z ) ];
        
        $aBlock->[$i][$j][$k] = $elem;
    }}}
    
    return $aBlock;
}

sub Array2DSwapAxes ($)
{
    my ($array2d) = @ARG;

    warn "Prefer Array2d::SwapAxes at ".caller()."\n";

    my $swapped = [];

    my $i;
    my $xLength;
    my $j;
    my $yLength;

    for( $i=0; $i< scalar( @$array2d );           $i++ ){
    for( $j=0; $j< scalar( @{ $array2d->[$i] } ); $j++ )
    {
        $swapped->[$j][$i] = $array2d->[$i][$j];
    }}
    
    return $swapped;
}

#***********************************************************
# ArrayDiff
# 
# Description:
# 
#     Given two arrays ArrayDiff returns the element
#    values (a) present in the first array only;
#    (b) present in the secont array only;
#    (c) common to both. Either or both arrays may
#    be degenerate.
#
#    In set-theory terms:
#    
#    given { A = {...}, B = {...} }
#    returns { A\B, B\A, AnB }
#            where n == intersection
#    
#
# Input:
# 
# (ra)        array1    = one array of data
#
# (ra)        array2    = another array of data
# 
#
# Output:
# 
# (ra)        aArray1Not2    = values in array1 only
# 
# (ra)        aArray2Not1     = values in array2 only
#
# (ra)        aIntersect    = values common to both
#

sub ArrayDiff ($$)
{
    my( $array1, $array2 ) = @ARG;

    my $aArray1Not2 = [];
    my $aArray2Not1 = [];
    my $aIntersect = [];

    my %hArray1UniqueElem = ();
    my %hArray2UniqueElem = ();
    my $hUnionElemFreq;

    my $elem;
    my $elemFreq;

    #---------------------------------
    #- get unique elements of each set
    #---------------------------------

    @hArray1UniqueElem{ @$array1 } = (); 
    @hArray2UniqueElem{ @$array2 } = ();

    #--------------------------------------------------
    #- get the union of set1(unique) u set2(unique)
    #- make a frequency table of elements in this union
    #--------------------------------------------------

    $hUnionElemFreq = HashElementFrequencies([ keys %hArray1UniqueElem, keys %hArray2UniqueElem ]);

    while( ($elem, $elemFreq) = each %$hUnionElemFreq )
    {
        #----------------------------------------------------
        #- non-intersection elements will appear only once...
        #----------------------------------------------------
        if( 1 == $elemFreq )
        {
            if(exists $hArray1UniqueElem{ $elem } )
            {
                push @$aArray1Not2, $elem;
            }
            else
            {
                push @$aArray2Not1, $elem;
            }
        }
        #--------------------------------------------------
        #- ...while intersection elements will appear twice
        #--------------------------------------------------
        else
        {
            push @$aIntersect, $elem;
        }
    }

    Prefer( wantarray, "Client should accept array from method" );

    return ( $aArray1Not2, $aArray2Not1, $aIntersect );
}
        
sub ArrayCommon ($)
{
    my( $array2d ) = @ARG;

    my $flatUniqArrays = [];
    my $array;

    my $aCommon;
    my $nArrays;

    my $hElemFreq;
    my $elem;
    my $elemFreq;

    for $array (@$array2d)
    {
        push @$flatUniqArrays, @{ UniqueElements( $array ) };
    }

    $hElemFreq = HashElementFrequencies( $flatUniqArrays );

    $nArrays = scalar( @$array2d );
    $aCommon = [];

    while( ($elem, $elemFreq) = each %$hElemFreq )
    {
        if( $nArrays == $elemFreq )
        {
            push @$aCommon, $elem;
        }
    }
    return $aCommon;
}

#***********************************************************
# MakePhysicalHistogram
# 
# Description:
# 
#     puts array data into physical bins, represented by a
#    2d array. Allows 'aces high' mode, in which a number
#    corresponding to the upper boundary of a bin is placed
#    within that bin, or 'aces low' mode, in which that
#    number would be placed in the next bin up.
#
# Input:
# 
# (ra)        aData    = array of data which may or may not be
#              in the range minVal -> maxVal
# 
# (int)        nBins    = the number of bins to be used
#
# (double)    maxVal    = the maximum value of the range in which
#              to calculate bins
#
# (double)    minVal    = the minimum value of the range in which
#              to calculate bins
#
# (boolean)     acesHighMode    = whether a datum corresponding
#                  to a bin boundary is stored in
#                  the lower bin (true) or the higher
#                  bin
#
# Output:
# 
# (ra)        aBins    = array of bins. Each bin is itself an array
#              containing all the data in that bin.
# 

sub MakePhysicalHistogram
{
    my ( $aData, $nBins, $minVal, $maxVal, $acesHighMode, $aliasingFunc ) = @ARG;

    5 == @ARG
    or 6 == @ARG
    or WrongNumArgsError();

    Assert( IsInt($nBins), "Number of bins must be an integer");

    my $aBins;
    my $binNumber;
    my $range;
    my $integer;
    my $fraction;
    my $binSize;
    my $nElems;
    my $elem;
    my $i;

    $range = $maxVal - $minVal;
    $binSize = $range / $nBins;
    $aBins = [];

    $nElems        = scalar(@$aData);

    for($i=0; $i<$nElems; $i++)
    {
        if($aliasingFunc)
        {
            $elem    = &$aliasingFunc( $aData->[$i] );
        }
        else
        {
            $elem    = $aData->[$i];
        }
        #-----------------------
        #- If datum is in range
        #-----------------------
        if( $elem >= $minVal
        and $elem <= $maxVal )
        {
            #------------------------------------
            #- If datum is on the edge of the range
            #------------------------------------
            if($minVal == $elem)
            {
                $binNumber = 0;
            }
            elsif( $maxVal == $elem )
            {
                $binNumber = $nBins - 1;
            }
            #-----------------------------------------
            #- If datum is somewhere within the range
            #-----------------------------------------
            else
            {
                ($fraction, $integer) = modf( ($elem - $minVal) / $binSize );
                #-------------------------------------
                #- If datum is somewhere within a bin
                #-------------------------------------
                if( $fraction )
                {
                    $binNumber = $integer;
                }
                #----------------------------------------
                #- If datum is sitting on a bin boundary
                #----------------------------------------
                elsif( $acesHighMode )
                {
                    $binNumber = $integer - 1;
                }
                else # i.e., aces low
                {
                    $binNumber = $integer;
                }
            }
            #-------------------------
            #- Push datum into its bin
            #-------------------------
            push @{ $aBins->[ $binNumber ] }, $aData->[$i];
        }
    }

    return $aBins;
}

#***********************************************************
# MakeHistogram
# 
# Description:
# 
#     puts array data into bins, returning a list of
#    integers corresponding to the population sizes of 
#    the bins. Allows 'aces high' mode, in which a number
#    corresponding to the upper boundary of a bin is placed
#    within that bin, or 'aces low' mode, in which that
#    number would be placed in the next bin up.
#
# Input:
# 
# (ra)        aData    = array of data which may or may not be
#              in the range minVal -> maxVal
# 
# (int)        nBins    = the number of bins to be used
#
# (double)    maxVal    = the maximum value of the range in which
#              to calculate bins
#
# (double)    minVal    = the minimum value of the range in which
#              to calculate bins
#
# (boolean)     acesHighMode    = whether a datum corresponding
#                  to a bin boundary is stored in
#                  the lower bin (true) or the higher
#                  bin
#
# Output:
# 
# (ra)        aBinPopSizes    = array of ints representing bin
#                population sizes.
# 

sub MakeHistogram
{
    my ( $aData, $nBins, $minVal, $maxVal, $acesHighMode, $aliasingFunc ) = @ARG;

    5 == @ARG
    or 6 == @ARG
    or WrongNumArgsError();

    my $aBinPopSizes;
    my $binNumber;
    my $range;
    my $integer;
    my $fraction;
    my $binSize;
    my $nElems;
    my $elem;
    my $i;

    Assert( ceil($nBins) == $nBins, "Number of bins must be an integer");

    $range         = $maxVal - $minVal;
    $binSize     = $range / $nBins;
    @$aBinPopSizes     = (0) x $nBins;

    $nElems        = scalar(@$aData);

    for($i=0; $i<$nElems; $i++)
    {
        if($aliasingFunc)
        {
            $elem    = &$aliasingFunc( $aData->[$i] );
        }
        else
        {
            $elem    = $aData->[$i];
        }
        #-----------------------
        #- If datum is in range
        #-----------------------
        if( $elem >= $minVal
        and $elem <= $maxVal )
        {
            #------------------------------------
            #- If datum is on the edge of the range
            #------------------------------------
            if($minVal == $elem)
            {
                $binNumber = 0;
            }
            elsif( $maxVal == $elem )
            {
                $binNumber = $nBins - 1;
            }
            #-----------------------------------------
            #- If datum is somewhere within the range
            #-----------------------------------------
            else
            {
                ($fraction, $integer) = modf( ($elem - $minVal) / $binSize );
                #-------------------------------------
                #- If datum is somewhere within a bin
                #-------------------------------------
                if( $fraction )
                {
                    $binNumber = $integer;
                }
                #----------------------------------------
                #- If datum is sitting on a bin boundary
                #----------------------------------------
                elsif( $acesHighMode )
                {
                    $binNumber = $integer - 1;
                }
                else # i.e., aces low
                {
                    $binNumber = $integer;
                }
            }
            #------------------------------
            #- Increment count for it's bin
            #------------------------------
            $aBinPopSizes->[ $binNumber ]++;
        }
    }

    return $aBinPopSizes;
}

sub SortParalellArrays_Num
{
    my ($aRef, @aParas) = @ARG;
    
    2 >= @ARG or WrongNumArgsError();
    
    my $aSortedRef;
    my @aSortedParas;
    my @aIndices;
    my $nElems;
    my $nParas;
    my $i;
    my $j;
    
    $nElems = scalar(@$aRef);
    $nParas = scalar(@aParas);
    @aIndices = (0..($nElems-1));
    
    @aIndices = sort { $aRef->[$a] <=> $aRef->[$b] } @aIndices;
    
    $aSortedRef     = [];
    @aSortedParas     = ();
        
    for($i=0; $i<$nElems; $i++)
    {
        $aSortedRef->[$i] = $aRef->[ $aIndices[$i] ];
        
        for($j=0; $j<$nParas; $j++)
        {
            $aSortedParas[$j][$i] = $aParas[$j][ $aIndices[$i] ];
        }
    }
    
    return ($aSortedRef, @aSortedParas);
}

sub SortParalellArrays_String
{
    my ($aRef, @aParas) = @ARG;
    
    2 >= @ARG or WrongNumArgsError();
    
    my $aSortedRef;
    my @aSortedParas;
    my @aIndices;
    my $nElems;
    my $nParas;
    my $i;
    my $j;
    
    $nElems = scalar(@$aRef);
    $nParas = scalar(@aParas);
    @aIndices = (0..($nElems-1));
    
    @aIndices = sort { $aRef->[$a] cmp $aRef->[$b] } @aIndices;
    
    $aSortedRef     = [];
    @aSortedParas     = ();
        
    for($i=0; $i<$nElems; $i++)
    {
        $aSortedRef->[$i] = $aRef->[ $aIndices[$i] ];
        
        for($j=0; $j<$nParas; $j++)
        {
            $aSortedParas[$j][$i] = $aParas[$j][ $aIndices[$i] ];
        }
    }
    
    return ($aSortedRef, @aSortedParas);
}

sub TraverseHashTree ($$)
{
    my ($parentNode, $aPath) = @ARG;
    my $childName = shift @$aPath;
    
    if(exists $parentNode->{$childName})
    {
        if(@$aPath)
        {
            return TraverseHashTree($parentNode->{$childName}, $aPath);
        }
        else
        {
            return $parentNode->{$childName};
        }
    }
    else
    {
        return false;
    }
}

sub NewArray
#_ either     NewArray( size ) or 
#_         NewArray( size, value )
#_ if size == 0, will confess with WrongNumArgsError
{
    my $size    = $ARG[0] || WrongNumArgsError();
    my $array;
    
    if(2 == @ARG)
    {
        $array = [($ARG[1]) x $size ];
    }
    else
    {
        $array = [];
        $#{$array} = $size - 1;
    }
    return $array;
} 
    
sub BarChart ($$$)
{
    my ($aData, $maxNumBarUnits, $barUnit) = @ARG;
    my $aBars;
    my $maxDatum;
    my $datum;
    
    $aBars = [];
    $maxDatum = ArrayMax($aData);
    for $datum (@$aData)
    {
        push @$aBars,
            ($barUnit x
                (
                    floor
                    (
                        (0 == $maxDatum? 0 : ($datum/$maxDatum))
                        *
                        $maxNumBarUnits
                    )
                )
            );
    }
    return $aBars;
}
    
sub ArrayLTransformToRange($$$$$)
{
    my($array, $dataMin, $dataMax, $newMin, $newMax) = @ARG;
    
    my $elem;
    
    for $elem (@$array)
    {
        $elem = ($elem-$dataMin)*($newMax-$newMin)/($dataMax-$dataMin) + $newMin;
    }
}

sub SetEquals($$)
{
    my($arrayA, $arrayB) = @ARG;
    my (%hA, $elemB);
    
    if(@$arrayA != @$arrayB)
    {
        return false;
    }
    else
    {
        @hA{@$arrayA} = ();
        for $elemB (@$arrayB)
        {
            if(not exists $hA{$elemB})
            {
                return false;
            }
        }
    }
    return true;
}

sub ArraySum($)
{
    my $array = shift @ARG;
    my $sum = 0;
    my $elem;
    
    for $elem (@$array)
    {
        $sum += $elem;
    }
    return $sum;
}

sub ArrayMean($)
{
    my $array = shift @ARG;
    my $sum = 0;
    my $elem;
    
    for $elem (@$array)
    {
        $sum += $elem;
    }
    return $sum/scalar(@$array);
}

sub UniqueSets_Slow($)
{
    my $aSets     = shift @ARG;
    my $aUniqSets     = [];

    my $aIsDup = NewArray(scalar(@$aSets), false);
    my ($i,$j);
    
    # Identify duplicates and register them as duplicates in $aIsDup
    for($i=0; $i<@$aSets - 1; $i++)
    {
        if(false == $aIsDup->[$i])
        {
            for($j=$i+1; $j<@$aSets; $j++)
            {
                if(false == $aIsDup->[$j]
                and SetEquals($aSets->[$i], $aSets->[$j]))
                {
                    $aIsDup->[$j] = true;
                }
            }
        }
    }
    
    # make array of sets that passed the dup test
    for($i=0; $i<@$aSets; $i++)
    {
        if(false == $aIsDup->[$i])
        {
            push @$aUniqSets, $aSets->[$i];
        }
    }
    return $aUniqSets;    
}


sub UniqueSets($)
{
    my $aSets       = shift @ARG;
    my $aUniqSets   = [];
    my $aIsDup = NewArray(scalar(@$aSets), false);
    my ($i,$j);
    my %tab_i;
    my $elem_j;
    my $isDup;
    
    for($i=0; $i<@$aSets - 1; $i++)
    {
        #-----------------------------------
        # See if set i is clean
        #-----------------------------------
        if(false == $aIsDup->[$i])
        {
            #-----------------------------------
            # put i values in to a table
            #-----------------------------------
            %tab_i = ();
            @tab_i{@{$aSets->[$i]}} = ();
            for($j=$i+1; $j<@$aSets; $j++)
            {
                #-----------------------------------
                # see if set j is clean
                #-----------------------------------
                if(false == $aIsDup->[$j])
                {
                    #-----------------------------------
                    # Compare i with j
                    #-----------------------------------
                    $isDup = true;
                    for $elem_j (@{$aSets->[$j]})
                    {
                           if(not exists $tab_i{$elem_j})
                           {
                               $isDup = false;
                               last;
                           }
                    }
                    $aIsDup->[$j] = true if $isDup;
                    
                }#endif
            }#endfor
        }#endif
    }#endfor
    
    for($i=0; $i<@$aSets; $i++)
    {
        if(false == $aIsDup->[$i])
        {
            push @$aUniqSets, $aSets->[$i];
        }
    }
    
    return $aUniqSets;    
}

sub HashAgainstIndices($)
{
    my $array = shift @ARG;
    my $hash = {};
    my $i;
    
    for($i=0; $i<@$array; $i++)
    {
        $hash->{$array->[$i]} = $i;
    }
    return $hash;
}

sub SetIntersect($)
# assumes every array is non-redundant
{
    my $aSets = shift @ARG;
    
    my $hElemFreqs     = HashElementFrequencies(Array2DFlatten($aSets));
    my $nSets     = scalar @$aSets;
    my $aIntersect     = [];
    
    my ($elem, $freq);
    while(($elem, $freq) = each %$hElemFreqs)
    {
        if($nSets == $freq)
        {
            push @$aIntersect, $elem;
        }
    }
    return $aIntersect;
}

sub Array2DFlatten($)
{
    my $array2d     = shift @ARG;
    my $flatArray     = [];
    my $array;
    for $array (@$array2d)
    {
        push @$flatArray, @$array;
    }
    return $flatArray;
}

sub BinDatum($$$$$)
{
    my ($nBins, $minVal, $maxVal, $acesHighMode, $datum) = @ARG;
    my $binNumber = -1;

    #-----------------------
    #- If datum is in range
    #-----------------------
    if( $datum >= $minVal
    and $datum <= $maxVal )
    {
        #------------------------------------
        #- If datum is on the edge of the range
        #------------------------------------
        if(    $minVal == $datum)
        {
            $binNumber = 0;
        }
        elsif(     $maxVal == $datum )
        {
            $binNumber = $nBins - 1;
        }
        #-----------------------------------------
        #- If datum is somewhere within the range
        #-----------------------------------------
        else
        {
            my $binSize = ($maxVal - $minVal) / $nBins;
            my($fraction, $integer) = modf( ($datum - $minVal) / $binSize );
            #-------------------------------------
            #- If datum is somewhere within a bin
            #-------------------------------------
            if( $fraction )
            {
                $binNumber = $integer;
            }
            #----------------------------------------
            #- If datum is sitting on a bin boundary
            #----------------------------------------
            elsif( $acesHighMode )
            {
                $binNumber = $integer - 1;
            }
            else # i.e., aces low
            {
                $binNumber = $integer;
            }
        }
    }
    #------------------------------------
    #- return number of bin to increment
    #------------------------------------
    return $binNumber;
}

sub ElementFranks($$)
#_ F(ractional) r(anks)
{
    my($aData, $aSortedData) = @ARG;
    
    my $hDatum2Rank = HashOneToOne($aSortedData, Nr::crank($aSortedData));
    my $nElem = scalar(@$aData);
    return Transform($aData, [],
            sub{ $hDatum2Rank->{$ARG[0]} / $nElem });
}
    
sub ElementRanks($$)
{
    my($aData, $aSortedData) = @ARG;
    my $hDatum2Rank = HashOneToOne($aSortedData, Nr::crank($aSortedData));
    return Transform($aData, [], sub{ $hDatum2Rank->{$ARG[0]}});
}

sub TransformArrayToHash
{
    return _TransformArrayToHash_2Arg(@ARG) if 2 == @ARG;
    return _TransformArrayToHash_3Arg(@ARG) if 3 == @ARG;
    WrongNumArgsError();
}  

sub _TransformArrayToHash_3Arg
{
    my($array, $keyFunc, $valueFunc) = @ARG;
    
    my $hash = {};
    for my $elem (@$array)
    {
        $hash->{ &$keyFunc($elem) } = &$valueFunc($elem);
    }
    return $hash;
}


sub _TransformArrayToHash_2Arg
{
    my($array, $keyFunc) = @ARG;
    
    my $hash = {};
    for my $elem (@$array)
    {
        $hash->{ &$keyFunc($elem) } = $elem;
    }
    return $hash;
}

sub ArrayAdd($$$)
{
    my($arrayA, $arrayB, $aTarget) = @ARG;
    
    scalar(@$arrayA) == scalar(@$arrayB) or Fatal("arrays must be same size");
    for (my $i=0; $i<@$arrayA; $i++)
    {
        $aTarget->[$i] = $arrayA->[$i] + $arrayB->[$i];
    }
    return $aTarget;
}

sub ArrayResize($$)
{
    my($array, $newSize) = @ARG;
    $#{$array} = $newSize - 1;
}

true;
