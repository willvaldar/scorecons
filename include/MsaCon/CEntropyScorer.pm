use strict;
#==============================================================================
# CLASS: MsaCon::CEntropyScorer
#==============================
# DESCRIPTION:
#

#_ Class declaration

package MsaCon::CEntropyScorer;

#_ Include libraries

use English;
use StdDefs;
use Array;
use Algorithm qw(Transform);
use VUtils::Math qw(Shannon);

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

#_ Constructor

sub new ($)
{
    my $class = shift;
    my $this = {
            'aln' => null,
            };
    return bless $this, $class;
}

#_ Public instance methods

#inline

sub getAln($)    {$ARG[0]{'aln'}}
sub setAln($$)   {$ARG[0]{'aln'} = $ARG[1]}

#non-inline

sub scorePos($$)
{
    my($this, $pos) = @ARG;
    return $this->scoreColumn($this->getAln->getColumnResidues($pos));
}

sub scoreColumn($$)
{
    my($this, $aAminos) = @ARG;
    
    my $hAminoFreqs = Array::ElementFrequencies($aAminos);
    my $fractionalFreqs = Transform([values %{$hAminoFreqs}], [],
            sub{$ARG[0]/scalar(@$aAminos)});
    return Shannon($fractionalFreqs);
}               

#====
# END
#==============================================================================
true;
