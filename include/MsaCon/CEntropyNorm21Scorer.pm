use strict;
#==============================================================================
# CLASS: MsaCon::CEntropyNorm21Scorer
#====================================
# DESCRIPTION:
#

#_ Class declaration

package MsaCon::CEntropyNorm21Scorer;

#_ Include libraries

use English;
use StdDefs;
use Assert;
use MsaCon::CEntropyNormMappedScorer;
use base qw(MsaCon::CEntropyNormMappedScorer);

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#_ Class variables

my %hAminoMapping = (
        # 20 standard amino acids
        'A' => 'A',
        'C' => 'C',
        'D' => 'D',
        'E' => 'E',
        'F' => 'F',
        'G' => 'G',
        'H' => 'H',
        'I' => 'I',
        'K' => 'K',
        'L' => 'L',
        'M' => 'M',
        'N' => 'N',
        'P' => 'P',
        'Q' => 'Q',
        'R' => 'R',
        'S' => 'S',
        'T' => 'T',
        'V' => 'V',
        'W' => 'W',
        'Y' => 'Y',
        # gaps
        CSequence::GAP_CHAR => CSequence::GAP_CHAR,
        );
my $nonStdCode = CSequence::GAP_CHAR;
my $numTypes = 21;

#_ Constructor

sub new ($)
{
    my $class = shift;
    my $this = $class->SUPER::new($numTypes);
    return bless $this, $class;
}

#_ Private instance methods

sub _mapAmino($$)
{
    my($this, $amino) = @ARG;
    
    return exists $hAminoMapping{$amino}
            ? $hAminoMapping{$amino}
            : $nonStdCode;
}
    
#====
# END
#==============================================================================
true;
