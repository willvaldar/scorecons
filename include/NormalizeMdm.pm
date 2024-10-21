use strict;
#==============================================================================
# MODULE: NormalizeMdm
#=====================
# DESCRIPTION:
#

#_ Module declaration

package NormalizeMdm;

#_ Include libraries

use English;
use StdDefs;
use VUtils::DataManip qw(Hash2DRange);

sub LinearRange($$$)
{
    my($oldMatrix, $floor, $ceiling) = @ARG;
    
    my($range, $min, $max) = Hash2DRange($oldMatrix);
    
    my $newMatrix = new CMdm;
    my $aKeys = $oldMatrix->getAxis;
    for (my $i=0; $i<@$aKeys; $i++)
    {
        for (my $j=0; $j<@$aKeys; $j++)
        {
            my $a = $aKeys->[$i];
            my $b = $aKeys->[$j];
            my $value = ($oldMatrix->getTransition($a,$b) - $min) / $range;
            $value = ($value + $floor)*($ceiling - $floor);
            $newMatrix->setTransition($a, $b, $value);
        }
    }
    return $newMatrix;
}

sub Karlin($)
{
    my $oldMatrix = shift;
    my $newMatrix = new CMdm;

    my $aKeys = $oldMatrix->getAxis;
    for (my $i=0; $i<@$aKeys; $i++)
    {
        for (my $j=0; $j<@$aKeys; $j++)
        {
            my $a = $aKeys->[$i];
            my $b = $aKeys->[$j];
            my $m_ab = $oldMatrix->getTransition($a,$b);
            my $m_aa = $oldMatrix->getTransition($a,$a);
            my $m_bb = $oldMatrix->getTransition($b,$b);
            #print "$a:$b: $m_ab / root( $m_aa * $m_bb )\n";
            my $value = $m_ab / sqrt($m_aa*$m_bb);
            
            $newMatrix->setTransition($a, $b, $value);
        }
    }
    return $newMatrix;
}
    

#====
# END
#==============================================================================
true;
