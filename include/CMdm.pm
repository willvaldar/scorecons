use strict;
#------------------------------------------------------------------------------
package CMdm;
use English;
use StdDefs;
use Assert;
use String qw(Trim);
use VUtils::DataManip qw(Hash2DRange Hash2DCopy);

#--------------------------#
# Interface                #
#--------------------------#

#_ Public

sub new;

sub getValueRange($);
sub getSize($);
sub getAxis($);
sub getMatrixValues($);
sub getTransition($$$);

sub setMatrix($$$);
sub setTransition($$$$);
sub setTransitionXvsNotX($$$);

sub clone($);
sub cloneOnly($$);
#sub cloneExcept($$);

#_ Private

sub _loadMDM($$);
sub _clearMatrix($);

#--------------------------#
# Implementation           #
#--------------------------#

sub new
{
    my $class  = $ARG[0];
    my $fhMatrix = $ARG[1] || null;
    
    my $this = {};
    
    bless $this, $class;
    
    if($fhMatrix)
    {
        $this->_loadMDM($fhMatrix);
    }
    
    return $this;
}

sub getValueRange ($)
{
    return Hash2DRange($ARG[0]);
}

sub getSize ($)
{
    return scalar keys %{$ARG[0]}
}

sub getAxis ($)
{
    return [sort keys %{$ARG[0]}]
}

sub getMatrixValues ($)
{
    my $this = shift @ARG;
    
    my $array2d = [];
    my $axis = $this->getAxis;
    
    for (my $i=0; $i<@$axis; $i++){
    for (my $j=0; $j<@$axis; $j++)
    {
        $array2d->[$i][$j] = $this->getTransitionProb($axis->[$i],$axis->[$j]);
    }}
    
    return $array2d;
}

sub getTransition ($$$)
{
    my($this, $a, $b) = @ARG;
    
    if (not exists $this->{$a}{$b})
    {
         Fatal("M($a,$b) not found in matrix");
    }
    
    return $this->{$a}{$b};
}
    
sub setMatrix ($$$)
{
    my ($this, $array2d, $axis) = @ARG;
    $this->_clearMatrix;
    
    for(my $i=0;$i<@$axis; $i++){
    for(my $j=0; $j<@$axis; $j++)
    {
        $this->setTransition($axis->[$i], $axis->[$j], $array2d->[$i][$j]);
    }}
}
    
sub setTransition ($$$$)
{
    my ($this, $a, $b, $prob) = @ARG;

    $this->{$a}{$b} = $prob;
}

sub setTransitionXvsNotX ($$$)
{
    my ($this, $a, $prob) = @ARG;
    my $axis = $this->getAxis;
    
    for(my $i=0;$i<@$axis; $i++)
    {
        my $b = $axis->[$i];
        if($a ne $b)
        { 
            $this->{$a}{$b} = $prob;
            $this->{$b}{$a} = $prob;
        }
    }
}

sub clone ($)
{
    my $this = shift @ARG;
    
    return bless Hash2DCopy($this), ref($this);
}

sub cloneOnly($$)
{
    my($this, $aAcceptedSymbols) = @ARG;
    
    my $newMatrix = new CMdm;
    for (my $i=0; $i<@$aAcceptedSymbols; $i++)
    {
        for (my $j=0; $j<@$aAcceptedSymbols; $j++)
        {
            my $a = $aAcceptedSymbols->[$i];
            my $b = $aAcceptedSymbols->[$j];
            $newMatrix->setTransition($a,$b,
                    $this->getTransition($a,$b));
        }
    }
    return $newMatrix;
}

sub _loadMDM ($$)
{
    my($this, $fhMatrix) = @ARG;
    
    my $axis = null;
    my $array2d = [];
    while (my $line = $fhMatrix->getline )
    {
        if($line =~ m/^[^!\#].*?\S/)
        {
            if (!$axis)
            {
                $axis = [ (split m/\s+/, String::Trim($line)) ];
            }
            else
            {
                my @aAll = split m/\s+/, String::Trim($line);
                shift @aAll;
                push @$array2d, [@aAll];
            }
        }
    }
    $this->setMatrix($array2d, $axis);
}

sub _clearMatrix ($)
{
    my $this = shift;
    
    while (my($key, $value) = each %$this)
    {
        delete $this->{$key};
    }
}

#---logical end of class---#

if(!caller){Static_Main()}

sub Static_Main ()
{
    #------------------------------------------------------------------------------
    package main;
    use English;
    use StdDefs;
    use strict;
    use FileIoHelper qw(OpenFilesForReading);
    
    require "dumpvar.pl";
    
    my $matrixFile           = '/home/bsm/martin/data/pet91.mat'; 
    my $matrix;
    $matrix = new CMdm(OpenFilesForReading($matrixFile));
    
    print "***Normal\n";
    
    dumpValue(\$matrix);
    
    print "Range:\t", join(',', $matrix->getValueRange), "\n";
    print "Size:\t", $matrix->getSize, "\n";
    print "Matrix:\n";
    dumpValue($matrix->getAxis);
    dumpValue($matrix->getMatrixValues);
    print "P(A,C):\t", $matrix->getTransitionProb('A','C'), "\n";
    
    print "***Set Gaps\n";
    
    $matrix->setTransitionProbXvsNotX('-',100);
    $matrix->setTransitionProb('-','-',-99);    

    print "Range:\t", join(',', $matrix->getValueRange), "\n";
    print "Size:\t", $matrix->getSize, "\n";
    print "Matrix:\n";
    dumpValue($matrix->getAxis);
    dumpValue(\$matrix);
    print "P(A,C):\t", $matrix->getTransitionProb('A','C'), "\n";
    
    print "***Transformed\n";
    
    $matrix->transformToRangeZeroOne;

    print "Range:\t", join(',', $matrix->getValueRange), "\n";
    print "Size:\t", $matrix->getSize, "\n";
    print "Matrix:\n";
    dumpValue($matrix->getAxis);
    dumpValue(\$matrix);
    print "P(A,C):\t", $matrix->getTransitionProb('A','C'), "\n";
        
    #------------------------------------------------------------------------------
}

true;
