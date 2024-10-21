use strict;
#==============================================================================
# CLASS: MsaCon::CWeightedMdmVT00Scorer;
#=======================================
# DESCRIPTION:
#

#_ Class declaration
package MsaCon::CValdar01Scorer;

#_ Include libraries
use English;
use StdDefs;
use CSequence;
use NormalizeMdm;

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

#_ Constructor

sub new($$)
{
    my($class, $matrix) = @ARG;
    
    my $this = {
        'aln'        => null,
        'matrix'     => $matrix,
        'seqWeights' => null,
        'maxScore'   => 0,
        };
        
    return bless $this, $class;
}

#_ Public instance methods

sub setAln($$)
{
    my ($this, $aln) = @ARG;
    
    $this->{'aln'} = $aln;
    
    $this->_makeSeqWeights;
}

sub scorePos($$)
{
    my($this, $i) = @ARG;
    
    my $col   = $this->{'aln'}->getColumnResidues($i);
    my $nSeqs = $this->{'aln'}->getNumSeqs;
    my $score = 0;
    for (my $i=0; $i<$nSeqs-1; $i++)
    {
        my $wi = $this->{'seqWeights'}[$i];
        my $ai = $col->[$i];
        for (my $j=$i+1; $j<$nSeqs; $j++)
        {
            my $wj = $this->{'seqWeights'}[$j];
            my $aj = $col->[$j];
            $score += $wi*$wj*($this->{'matrix'}{$ai}{$aj});
        }
    }
    return $score / $this->{'maxScore'};
}

#_ Private instance methods

sub _makeSeqWeights($)
{
    my $this = shift;
    
    #_ Calculate all pairwise similarities
    my $seqDistMatrix = [];
    my $nSeqs = $this->{'aln'}->getNumSeqs;
    for (my $i=0; $i<$nSeqs-1; $i++)
    {
        for (my $j=$i+1; $j<$nSeqs; $j++)
        {
            my $dist = $this->_seqDist($i,$j);
            $seqDistMatrix->[$i][$j] = $dist;
            $seqDistMatrix->[$j][$i] = $dist;
        }
    }
    
    #_ Calculate sequence weights
    $this->{'seqWeights'} = [];
    for (my $i=0; $i<$nSeqs; $i++)
    {
        my $sumDists = 0;
        for (my $j=0; $j<$nSeqs; $j++)
        {
            if ($i != $j)
            {
                $sumDists += $seqDistMatrix->[$i][$j];
            }
        }
        $this->{'seqWeights'}[$i] = $sumDists / ($nSeqs - 1);
    }
    
    # Calculate the maximum score for a column
    my $maxScore = 0;
    for (my $i=0; $i<$nSeqs-1; $i++)
    {
        for (my $j=$i+1; $j<$nSeqs; $j++)
        {
            $maxScore += $this->{'seqWeights'}[$i]
                    * $this->{'seqWeights'}[$j];
        }
    }
    $this->{'maxScore'} = $maxScore;
}
    
sub _seqDist($$$)
{
    my($this, $a, $b) = @ARG;
    
    my $seqA = $this->{'aln'}->getSeqResidues($a);
    my $seqB = $this->{'aln'}->getSeqResidues($b);
    
    my $length = $this->{'aln'}->getLength;
    my $pairLength = 0;
    my $sumMut = 0;
    for (my $i=0; $i<$length; $i++)
    {
        unless (CSequence::GAP_CHAR eq $seqA->[$i]
                && CSequence::GAP_CHAR eq $seqB->[$i])
        {
            $pairLength++;
            $sumMut += $this->{'matrix'}{$seqA->[$i]}{$seqB->[$i]};
        }
    }
    return 1 - $sumMut / $pairLength;
}
    
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
