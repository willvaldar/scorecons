use strict;
#==============================================================================
# CLASS: MsaCon::CEntropyNormScorer
#==================================
# DESCRIPTION:
#

#_ Class declaration

package MsaCon::CEntropyNormScorer;

#_ Include libraries

use English;
use StdDefs;
use Assert;
use MsaCon::CEntropyScorer;
use VUtils::Math qw(LogBase Min);

#------------------------------------------------------------------------------
# INTERFACE
#----------

#_ Public class constants

#_ Public class methods

#_ Constructor

sub new($$);
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

sub getNumTypes($);
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

sub setNumTypes($$);
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

#_ Constructor

sub new ($$)
{
    my($class, $numTypes) = @ARG;
    my $this = {
            'entropyScorer'=> new MsaCon::CEntropyScorer,
            'numTypes' => $numTypes,
            };
    return bless $this, $class;
}

#_ Public instance methods

#_ inline

sub getNumTypes($)      {$ARG[0]{'numTypes'}}
sub setNumTypes($$)     {$ARG[0]{'numTypes'} = $ARG[1]}

#_ non-inline

sub getAln($)
{
    my $this = shift;
    return $this->{'entropyScorer'}->getAln;
}

sub setAln($$)
{
    my ($this, $aln) = @ARG;
    $this->{'entropyScorer'}->setAln($aln);
}

sub scorePos($$)
{
    my($this, $pos) = @ARG;
    return $this->scoreColumn($this->getAln->getColumnResidues($pos));
}

sub scoreColumn($$)
{
    my($this, $aAminos) = @ARG;
    
    Assert(0 < $this->getNumTypes,
            "number of types must be > 0 for normalization");
    
    my $entropy = $this->{'entropyScorer'}->scoreColumn($aAminos);
    my $maxEntropy = LogBase(2,
            Min($this->getNumTypes, $this->getAln->getNumSeqs));
    return 1 - $entropy/$maxEntropy;
}
    
#====
# END
#==============================================================================
true;
