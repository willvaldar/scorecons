use strict;
#==============================================================================
# CLASS: MsaCon::CEntropyNormMappedScorer
#========================================
# DESCRIPTION: Base class
#

#_ Class declaration

package MsaCon::CEntropyNormMappedScorer;

#_ Include libraries

use English;
use StdDefs;
use Assert;
use MsaCon::CEntropyNormScorer;

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#_ Constructor

sub new ($$)
{
    my($class, $numTypes) = @ARG;
    my $this = bless {}, $class;
    $this->{'scorer'} = new MsaCon::CEntropyNormScorer($numTypes),
    return $this;
}

#_ Public instance methods

#_ non-inline

sub getAln($)
{
    my $this = shift;
    return $this->{'scorer'}->getAln;
}

sub setAln($$)
{
    my ($this, $aln) = @ARG;
    $this->{'scorer'}->setAln($aln);
}

sub scorePos($$)
{
    my($this, $pos) = @ARG;
    return $this->scoreColumn($this->getAln->getColumnResidues($pos));
}

sub scoreColumn($$)
{
    my($this, $aAminos) = @ARG;
    
    return $this->{'scorer'}->scoreColumn($this->_filterAminoList($aAminos));
}

sub _filterAminoList($$)
{
    my($this, $aOldAminos) = @ARG;
    
    my $aNewAminos = [];
    for my $amino (@$aOldAminos)
    {
        push @$aNewAminos, $this->_mapAmino($amino);
    }
    return $aNewAminos;
}

#---------------------------
# override this in subclass

sub _mapAmino($$)
{
    my($this, $amino) = @ARG;
    return $amino;
}

#====
# END
#==============================================================================
true;
