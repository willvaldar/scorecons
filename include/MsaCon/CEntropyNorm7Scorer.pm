use strict;
#==============================================================================
# CLASS: MsaCon::CEntropyNorm7Scorer
#===================================
# DESCRIPTION:
#

#_ Class declaration

package MsaCon::CEntropyNorm7Scorer;

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
        'A' => 'l',
        'C' => 'l',
        'D' => 'n',
        'E' => 'n',
        'F' => 'r',
        'G' => 's',
        'H' => 'r',
        'I' => 'l',
        'K' => 'p',
        'L' => 'l',
        'M' => 'l',
        'N' => 'o',
        'P' => 's',
        'Q' => 'o',
        'R' => 'p',
        'S' => 'o',
        'T' => 'o',
        'V' => 'l',
        'W' => 'r',
        'Y' => 'r',
        # gaps
        CSequence::GAP_CHAR => CSequence::GAP_CHAR,
        );
my $nonStdCode = CSequence::GAP_CHAR;
my $numTypes = 7;

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
