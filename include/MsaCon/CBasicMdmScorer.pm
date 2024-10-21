use strict;
#==============================================================================
# CLASS: MsaCon::CBasicMdmScorer
#===============================
# DESCRIPTION:
#

#_ Class declaration

package MsaCon::CBasicMdmScorer;

#_ Include libraries

use English;
use StdDefs;
use CSequence;

#------------------------------------------------------------------------------
# INTERFACE
#----------

#_ Public class constants

#_ Public class methods

#_ Constructor

sub new($);
# Constructor
# PRECONDITION:
# WARNING:
# ARGUMENTS:
# RETURN:
# SEE ALSO:

#_ Public instance methods

sub getAln($);
# Method: accessor
# PRECONDITION:
# WARNING:
# ARGUMENTS:
# RETURN:
# SEE ALSO:

sub setAln($$);
# Method: accessor
# PRECONDITION:
# WARNING:
# ARGUMENTS:
# RETURN:
# SEE ALSO:


#_ Private instance methods

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#_ Class constants

#_ Class variables

#_ Class init

#_ Class methods

#_ Constructor

sub new ($)
{
    my($class, $matrix) = @ARG;
    
    my $this = {
            'aln' => null,
            'matrix' => $matrix,
            };
    return bless $this, $class;
}

#_ Public instance methods

#_ inline

sub getAln($)    {$ARG[0]{'aln'}}
sub setAln($$)   {$ARG[0]{'aln'} = $ARG[1]}

#_ non-inline

sub scorePos($$)
{
    my($this, $pos) = @ARG;
    return $this->scoreColumn($this->getAln->getColumnResidues($pos));
}

sub scoreColumn($$)
{
    my($this, $aAminos) = @ARG;
    
    my $hAminoFreqs = Array::ElementFrequencies($aAminos);
    my $aUniqAminos = [keys %$hAminoFreqs];
    
    my $sum = 0;
    my $count = 0;
    
    for (my $i=0; $i<@$aUniqAminos; $i++)
    {
        my $amino_i     = $aUniqAminos->[$i];
        my $aminoFreq_i = $hAminoFreqs->{$amino_i};
        
        for (my $j=$i; $j<@$aUniqAminos; $j++)
        {
            my $amino_j = $aUniqAminos->[$j];
            # identity comparisons
            if ($amino_i eq $amino_j)
            {
                my $nCmp = $aminoFreq_i*($aminoFreq_i - 1)/2;
                my $sim  = $this->{'matrix'}{$amino_i}{$amino_i};
        
                $sum    += $nCmp * $sim;
                $count  += $nCmp;
            }
            # non-identity comparisons
            else
            {
                my $aminoFreq_j = $hAminoFreqs->{$amino_j};
                my $nCmp        = $aminoFreq_i * $aminoFreq_j;
                my $sim = $this->{'matrix'}{$amino_i}{$amino_j};
                
                $sum += $nCmp * $sim;
                $count += $nCmp;
            }
        }
    }
    return $sum/$count;
}
                
        

#_ Private instance methods

#====
# END
#==============================================================================
true;
