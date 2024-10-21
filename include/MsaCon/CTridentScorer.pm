use strict;
#==============================================================================
# CLASS: MsaCon::CMottScorer;
#============================
# DESCRIPTION:
#

#_ Class declaration
package MsaCon::CTridentScorer;

#_ Include libraries
use English;
use StdDefs;
use CSequence;
use CMoment;
use Algorithm qw(Transform CopyIf CountIf);
use Hash;
use Array;
use VUtils::Math qw(Shannon Sqr Min LogBase);
use VUtils::Protein qw(IsAmino1 GetArrayStdAminos1);
use Assert;

require "dumpvar.pl";
#------------------------------------------------------------------------------
# INTERFACE
#----------

#_ Public class constants

#_ Public class methods

#_ Constructor

#_ Public instance methods

#_ Private instance methods

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#_ Class constants

#_ Class variables

my $diversityExp = 1;
my $chemistryExp = 1/5;
my $gapCostExp = 2;

#_ Class init

#_ Class methods

#_ Constructor

sub new($$)
{
    my($class, $matrix) = @ARG;
        
    my $this = {
        'aln'         => null,
        'matrix'      => null,
        'matrixRange' => null,
        'aminoVectors'=> null,
        'seqWeights'  => null,
        'diversityExp' => 1,
        'chemistryExp' => 1,
        'gapCostExp'   => 1,
        };
    bless $this, $class;

    $this->setMatrix($matrix);
    
    return $this;
}

sub getChemistryExp($)    {$ARG[0]{'chemistryExp'}}
sub getDiversityExp($)    {$ARG[0]{'diversityExp'}}
sub getGapCostExp($)    {$ARG[0]{'gapCostExp'}}
sub getMatrix($)    {$ARG[0]{'matrix'}}

sub setChemistryExp($$)    {$ARG[0]{'chemistryExp'} = $ARG[1]}
sub setDiversityExp($$)    {$ARG[0]{'diversityExp'} = $ARG[1]}
sub setGapCostExp($$)    {$ARG[0]{'gapCostExp'} = $ARG[1]}


sub setMatrix($)
{
    my($this, $matrix) = @ARG;
    
    $matrix = $matrix->clone;

    $this->{'aminoVectors'} = _MakeAminoVectors($matrix);
    $this->{'matrix'} = $matrix;
    $this->{'matrixRange'} = $matrix->getValueRange;
}

sub _MakeAminoVectors($)
{
    my $matrix = shift;
    
    my $aAlphabet = GetArrayStdAminos1();
    my $hAminoVectors = {};
    for my $refAmino (@$aAlphabet)
    {
        my $vector = [];
        for my $amino (@$aAlphabet)
        {
            push @$vector, $matrix->getTransition($amino, $refAmino);
        }
        $hAminoVectors->{$refAmino} = $vector;
    }
    return $hAminoVectors;
}
    

sub getAln($){$ARG[0]->{'aln'}}

sub setAln($$)
{
    my ($this, $aln) = @ARG;
    
    $this->{'aln'} = $aln;
    
    $this->{'seqWeights'} = _MakeSeqWeights($aln);
}

sub scorePos($$)
{
    my($this, $i) = @ARG;
    
    my $diversity = $this->_scorePosDiversity($i);
    my $chemistry = $this->_scoreChemistry($i);
    my $gapCost = $this->_scoreGapCost($i);

    #print "$diversity\t$chemistry\t$gapCost\n";
    
    return (1 - $diversity)**$this->getDiversityExp
         * (1 - $chemistry)**$this->getChemistryExp
         * (1-$gapCost)**$this->getGapCostExp;
}

sub _scorePosDiversity($$)
{
    my($this, $pos) = @ARG;
    
    my $aResidues = $this->getAln->getColumnResidues($pos);
    my $aAminos = Array::Unique($aResidues);
    my $hAminoP = Array::ToHash($aAminos, sub{$ARG[0]}, sub{0});
    
    for (my $i=0; $i<@$aResidues; $i++)
    {
        my $amino = $aResidues->[$i];
        $hAminoP->{$amino} += $this->getSeqWeight($i);
    }

    my $diversity = Shannon([values %$hAminoP]);
    my $maxDiversity = LogBase(2, Min(21,$this->getAln->getNumSeqs));
    
    return $diversity/$maxDiversity;
}

sub _scoreChemistry($$)
{
    my($this, $pos) = @ARG;
    
    # get list of non-gap aminos
    my $aAminos = Array::Unique($this->getAln->getColumnResidues($pos));
    $aAminos = CopyIf($aAminos, [], \&IsAmino1);
    
    # handle situations like ---X--- or ------ in the alignment column
    if (0 == Array::Length($aAminos))
    {
        return 0;
    }
        
    # calculate centroid
    my $aAminoVectors = Transform($aAminos, [], sub{$this->_getAminoVector($ARG[0])});
    
    # calculate centroid
    my $centroidVector = Array_AverageValues(@$aAminoVectors);
    
    # calculate distances from centroid
    my $momentDist = new CMoment;
    
    for my $aminoVector (@$aAminoVectors)
    {
        $momentDist->put(EuclidDistance($aminoVector, $centroidVector));
    }
    
    my $maxDist = sqrt(
            Array::Length($centroidVector)
            *($this->{'matrixRange'})**2);
    
    return $momentDist->getMean / $maxDist;
}

sub _getAminoVector($$)
{
    my($this, $amino) = @ARG;
    
    return $this->{'aminoVectors'}{$amino};
}
    

sub EuclidDistance($$)
{
    my($vectA, $vectB) = @ARG;

    Assert(@$vectA==@$vectB, "input arrays must the same length");
    
    my $sqrDist = 0;
    for (my $i=0; $i<@$vectA; $i++)
    {
        $sqrDist += Sqr( $vectA->[$i] - $vectB->[$i] );
    }
    return sqrt($sqrDist);
}


sub Array_AverageValues
{
    my @arrayList = @ARG;

    my $aSum = Array_SumValues(@arrayList);
    
    return Transform($aSum, $aSum, sub{$ARG[0]/scalar(@arrayList)});
}
    
sub Array_SumValues
{    
    my @arrayList = @ARG;

    my $aSum = Array::New(scalar(@{$arrayList[0]}), 0);

    for my $array (@arrayList)
    {
        for (my $i=0; $i<@$array; $i++)
        {
            $aSum->[$i] += $array->[$i];
        }
    }
    return $aSum;
}
    

sub _scoreGapCost($$)
{
    my($this, $pos) = @ARG;
    
    my $aResidues = $this->getAln->getColumnResidues($pos);
    my $nGaps = CountIf($aResidues, sub{$ARG[0] eq CSequence::GAP_CHAR});
    return $nGaps / Array::Length($aResidues);
}
    
sub getSeqWeight($$)
{
    my($this, $i) = @ARG;
    return $this->{'seqWeights'}->[$i];
}
    

sub _MakeSeqWeights($)
{
    my $aln = shift;
    
    my $aMomentWeights = Array::New($aln->getNumSeqs);
    Transform($aMomentWeights, $aMomentWeights, sub{new CMoment});
    for (my $i=0; $i<$aln->getLength; $i++)
    {
        my $aColumnWeights = _MakeSeqColumnWeights($aln, $i);
        for (my $k=0; $k<$aln->getNumSeqs; $k++)
        {
            $aMomentWeights->[$k]->put($aColumnWeights->[$k]);
        }
    }
    
    my $seqWeights = [];
    for (my $i=0; $i<$aln->getNumSeqs; $i++)
    {
        $seqWeights->[$i] = $aMomentWeights->[$i]->getMean;
    }
    return $seqWeights;
}

sub _MakeSeqColumnWeights($$)
{
    my($aln, $pos) = @ARG;
    
    my $aAminos = $aln->getColumnResidues($pos);
    my $hAminoFreqs = Array::ElementFrequencies($aAminos);
    my $nAminoTypes = Hash::Size($hAminoFreqs);
    
    my $aWeights = [];
    for (my $i=0; $i<@$aAminos; $i++)
    {
        my $amino = $aAminos->[$i];
        my $aminoFreq = $hAminoFreqs->{$amino};
        $aWeights->[$i]= 1 / ($aminoFreq*$nAminoTypes);
    }
    return $aWeights;
}
    
      
    


#_ Public instance methods

#_ Private instance methods

#====
# END
#==============================================================================
true;

# DESCRIPTION:
# PRECONDITION:
# WARNING:
# ARGUMENTS:
# RETURN:
# SEE ALSO:
