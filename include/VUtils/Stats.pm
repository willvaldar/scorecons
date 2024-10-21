package VUtils::Stats;
use POSIX;
use English;
use VUtils::Math qw(Avg Sqr);
use VUtils::DataManip qw(NewArray);
use base qw(Exporter);
use Assert;
use strict;
#use PlatformDependent;
#use ProcessHandle;
use vars qw(@EXPORT_OK $PATH_pval_subsetsum);

@EXPORT_OK = qw(
        kstwo
        Correlation
        PvalSubSetSum
	    Median
        MatthewsCorrelation
        );


use constant EPS    => 3.0e-7;
use constant EPS1     => 0.001;
use constant EPS2     => 1.0e-8;
use constant FPMIN    => 1.0e-30;
use constant MAXIT    => 100;
use constant TINY    => 1.0e-20;

#$PATH_pval_subsetsum = $PlatformDependent::CProgDir . "/pval_subsetsum";

my $table_factln = NewArray(101, 0);

if(!caller)
{
    Static_Main();
}

sub Static_Main
{
    require "dumpvar.pl";

    my @data1 = ( 1..100 );
    my @data2 = map {$_*10} qw( 1 2 3 4 5 6 7 8 9 10 );

    my ($d, $prob) = kstwo(\@data1, \@data2);

    print "D:\t$d\n";
    print "prob:\t$prob\n";
}
sub ArrayRandSample_Accurate
{
    my ($dataSize, $sampleSize) = @ARG;
    
    Assert($dataSize && $sampleSize && $sampleSize <= $dataSize,
    "Cannot select $sampleSize points from set of $dataSize!\n");
    
    my $aiData;
    my $aiSample;
    my ($i, $randi, $tmp);
    
    $aiData     = [0..($dataSize-1)];
    $aiSample     = [];
    
    for($i=0; $i<$dataSize; $i++)
    {
        $randi             = floor(rand()*$dataSize);
        $tmp             = $aiData->[$i];
        $aiData->[$i]         = $aiData->[$randi];
        $aiData->[$randi]    = $tmp;
    }
    
    for($i=0; $i<$sampleSize; $i++)
    {
        push @$aiSample, $aiData->[$i];
    }
    
    return $aiSample;
}

sub ArrayRandSample_Approx
{
    my ($dataSize, $sampleSize) = @ARG;
    
    Assert($dataSize && $sampleSize && $sampleSize <= $dataSize,
    "Cannot select $sampleSize points from set of $dataSize!\n");

    my $aiSample;
    my $acceptProb;
    my $i;
    
    $acceptProb = $sampleSize / $dataSize;

    for($i=0; $i<$dataSize; $i++)
    {
        if(rand() < $acceptProb)
        {
            push @$aiSample, $i;
        }
    }
    
    return $aiSample;
}

sub MatthewsCorrelation($$$$)
{
    my($p, $n, $o, $u) = @ARG;

    return ($p*$n - $o*$u) /
            sqrt( ($p+$o)*($p+$u)*($n+$o)*($n+$u) );
}

sub Median
#_ The median of a distribution is estimated from a sample of values x1,...,
#_ xN by finding that value xi which has equal numbers of values above it and below
#_ it. Of course, this is not possible when N is even. In that case it is conventional
#_ to estimate the median as the mean of the unique two central values.
{
    my ($aData, $isSortedData) = @ARG;
    
    my $nData;
    my $midn;
    my $integral;
    my $fraction;
    
    $nData     = scalar @$aData;
    unless(defined($isSortedData) and $isSortedData)
    {
        $aData     = [ sort { $a <=> $b } @$aData ];
    }
    $midn     = $nData/2 - 1;    

    ($fraction, $integral) = modf($midn);

    if($fraction)
    {
        return $aData->[$integral];
    }
    else
    {
        return ( $aData->[$integral] + $aData->[$integral+1] ) / 2;
    }
}

#sub PvalSubSetSum($$$)
##_ Given a set of numbers A and its subset B, this function
##_ calculates the probability of chosing a random subset C for
##_ which sum(C) >= sum(B), where (C) = (B). i.e.,
##_ P(random >= actual).
##_   The function finds N random subsets of A
##_ and records how many give a sum greater or equal to that of B;
##_ where A is $aSet, B is $aSubSet, and N is $nTrials.
##_   Time taken is proportional to (B)x N, when (A) >> (B).
#{
#    my ($aSet, $aSubSet, $nTrials) = @ARG;
#    
#    my $pval;        # pvalue for subset sum
#    my $nBetterOrEqual;    # number of random subsets with sum >= subset
#    my $error;        # expected error (i.e., +/- error)
#
#    my $setFile;
#    my $subSetFile;
#    my $proc;
#    my (@procErrors, @procOutput);
#    my $line;
#    
#    #_
#    #_ Put reference data into temporary files so c prog
#    #_ can read them
#    #_
#    
#    $setFile     = "set"   .$PROCESS_ID.".txt";
#    $subSetFile     = "subset".$PROCESS_ID.".txt";
#    
#    WriteListToFile($setFile,    $aSet,    "\n");
#    WriteListToFile($subSetFile, $aSubSet, "\n");
#
#    #_
#    #_ Run external c program to calc pvalue
#    #_
#
#    $proc = new ProcessHandle($PATH_pval_subsetsum,
#                [
#                    $setFile,
#                    $subSetFile,
#                    scalar(@$aSet),
#                    scalar(@$aSubSet),
#                    $nTrials
#                ],
#                ProcessHandle::Read + ProcessHandle::ReadError);
#                
#    @procErrors = $proc->getErrorLines;
#    if(@procErrors)
#    {
#        warn "Warning: errors from $PATH_pval_subsetsum:\n", @procErrors;
#    }
#    @procOutput = $proc->getLines;
#    
#    $proc->closeAll;
#    
#    #_
#    #_ Parse output from c program
#    #_
#    
#    for $line (@procOutput)
#    {
#        if($line =~ m/better.+?:\s*(\S+)/)
#        {
#            $nBetterOrEqual = $1;
#        }
#        elsif($line =~ m/^Pvalue.*?:\s*(\S+)/)
#        {
#            $pval = $1;
#        }
#        elsif($line =~ m/^Error.*?:\s*(\S+)/)
#        {
#            $error = $1;
#        }
#    }
#    
#    #_
#    #_ Delete temporary data files
#    #_
#    
#    unlink $setFile, $subSetFile;
#    
#    return ($nBetterOrEqual, $pval, $error);
#}

sub Correlation ($$)
{
    my($aX, $aY) = @ARG;
    my $r;
    my $nelem;
    my $meanX;
    my $meanY;
    
    my $i;
    my $xt;
    my $yt;
    my $numtr;
    my $denomX;
    my $denomY;
    
    $nelem = @$aX;
    $meanX = Avg($aX);
    $meanY = Avg($aY);
    
    for($i=0; $i<$nelem; $i++)
    {
        $xt = ($aX->[$i] - $meanX);
        $yt = ($aY->[$i] - $meanY);
        $numtr += $xt * $yt;
        $denomX += Sqr($xt);
        $denomY += Sqr($yt);
    }
    $r = $numtr / sqrt($denomX * $denomY);

    return $r;
}

#_
#_ Supplementary methods
#_

sub SterlingLn($)
#_ Returns ln(n!) using Sterling's approximation
#_ ln(n!) ~ (n + 0.5)ln(n) + n + 0.5ln(2_pi_)
#_ Not as accurate as factln(), which uses the gamma function.
{
    my $n = shift;
    return ($n + 0.5) * log($n) - $n + 0.918938533269959;
}

sub Sterling($)
#_ Returns n! using Sterling's approximation
#_ n! ~ n^n * e^(-n) * sqrt(2_pi_n)
{
    my $n = shift;
    return $n**($n+0.5) * exp(-$n) * 2.50662827479465;
}

########NR#########

sub betacf
#_
#_ Used by betai: Evaluates continued fraction for incomplete beta
#_ function by modified Lentz's method
#_
{
    my ($a, $b, $x) = @ARG;
    my ($m, $m2);
    my ($aa, $c, $d, $del, $h, $qab, $qam, $qap);
    
    # These q's will be used in the factors that occur in the
    # coefficients
    
    $qab = $a + $b;
    $qap = $a + 1;
    $qam = $a - 1;
    
    # First step of Lentz's method
    
    $c = 1;
    $d = 1 - $qab * $x / $qap;
    
    if(FPMIN > abs $d){$d = FPMIN}
    
    $d = 1/$d;
    $h = $d;
    
    for ($m=1; $m<=MAXIT; $m++)
    {
        $m2 = 2 * $m;
        $aa = $m * ($b - $m) * $x / (($qam + $m2) * ($a + $m2));

        # Even step of the occurence
        
        $d = 1 + $aa * $d;
        if(FPMIN > abs $d){$d = FPMIN}
        $c = 1 + $aa / $c;
        if(FPMIN > abs $c){$c = FPMIN}
        
        $d = 1 / $d;
        $h *= $d * $c;

        $aa = -($a+$m)*($qab+$m)*$x/(($a+$m2)*($qap+$m2));
        
        # Odd step of the occurence
        
        $d = 1 + $aa * $d;
        if(FPMIN > abs $d){$d = FPMIN}
        $c = 1 + $aa / $c;
        if(FPMIN > abs $c){$c = FPMIN}

        $d = 1 / $d;
        $del = $d * $c;
        $h *= $del;

        # Are we done?

        if(EPS > abs($del-1))
        {
            last;
        }
    }
    
    Assert( !($m > MAXIT), "a or b too big, or MAXIT too small in betacf");
    
    return $h;
}

sub betai ($$$)
#_
#_ returns the incomplete beta function I (a,b)
#_                                       x
#_
{
    my ($a, $b, $x) = @ARG;
    my $bt;
    
    Assert( !($x < 0 || $x > 1), "bad value of x" );
    
    if(0 == $x || 1 == $x)
    {
        $bt = 0;
    }
    else
    # factors in front of the continued fraction
    {
        $bt = exp(     gammln($a+$b)
                - gammln($a)
                - gammln($b)
                + $a * log($x)
                + $b * log(1 - $x)
            );
    }
    
    if($x < ($a + 1)/($a + $b + 2))
    # use continued fraction directly
    {
        return $bt * betacf($a, $b, $x) / $a;
    }
    else
    # use continued fraction after making the symmetry transformation
    {
        return 1.0 - $bt * betacf($b, $a, 1-$x) / $b;
    }
}

sub bico($$)
#_ Returns the binomial coefficient n choose r.
#_  / n \         n! 
#_  |   |  = ___________   0 <= r <= n
#_  \ r /    r! (n - r)!
#_ The floor function cleans up roundoff error for smaller values of n and k.
{
    my ($n, $r) = @ARG;
    return floor(0.5 + exp( factln($n) - factln($r) - factln($n - $r)));
}

sub crank($)
#_ Given a sorted array aData[0..n-1], returns another array aRanks[0..n-1]
#_ containing ranks of the elements in aData. Includes midranking of ties
#_ and returns the s, the sum of f^3 - f, where f is the number of elements
#_ in each tie.
{
    my $aData = shift @ARG;
    
    my $n = @$aData;
    my $aRanks = [];
    my $s = 0;
    my $i = 0;
    
    while($i < $n-1 )
    {
        # not a tie
        if($aData->[$i+1] != $aData->[$i])
        {
            $aRanks->[$i] = $i + 1;
            $i++;
        }
        # a tie
        else
        {
            # how far does it go?
            my $jTie;
            for($jTie = $i + 1;
              $jTie < $n && $aData->[$jTie] == $aData->[$i];
              $jTie++){}

            my $rank = ($i + $jTie + 1) /2;
            
            for(my $ji=$i; $ji<=$jTie-1; $ji++)
            {
                $aRanks->[$ji] = $rank;
            }
            
            my $nTie = $jTie - $i;
            $s += $nTie**3 - $nTie;
            $i = $jTie;
        }
    }
    if($n - 1 == $i)
    {
        $aRanks->[$i] = $n;
    }
    return wantarray ? ($aRanks, $s) : $aRanks;
}

sub erfcc ($)
#_
#_ Returns the complementary error function erfc(x) with fractional error
#_ everywhere less than 1.2 * 10e-7
#_
{
    my $x = shift @ARG;
    my ($t, $z, $ans);
    
    $z = abs $x;
    $t = 1/(1 + 0.5 * $z);
    $ans = $t * exp
        (-$z * $z - 1.26551223 + $t*
            (1.00002368 + $t*
                (0.37409196 + $t*
                    (0.09678418 + $t*
                        (-0.18628806 + $t*
                            (0.27886807 + $t*
                                (-1.13520398 + $t*
                                    (1.48851587 + $t*
                                        (-0.82215223 + $t*0.17087277)
                                    )
                                )
                            )
                        )
                    )
                )
            )
        );
    return $x >= 0.0 ? $ans : 2.0 - $ans;
}

sub factln($)
#_ Returns ln(n!) 
{
    my $n = shift;
    
    if($n < 0){Fatal("Negative factorial\n")}
    if($n <= 1){return 0}
    if($n < @$table_factln)
    {
        return $table_factln->[$n] ? $table_factln->[$n]
                       : $table_factln->[$n] = gammln($n+1);
    }
    else
    {
        return gammln($n+1);
    }
}
    
sub factrl($)
#_ Returns n!
#_ Uses gamma function to approximate large n!
{
    my $n = shift;
    my ($i, $nf);
    
    if($n < 0){Fatal("Negative factorial\n")}
    if($n < 30)
    {
        for($i=$n-1, $nf = $n; $i > 1; $nf *= $i--){}
        return $nf;
    }
    else
    {
        return exp gammln($n+1);
    }
}

sub gammln ($)
#_
#_ returns the value ln(gamma(xx)) for xx > 0
#_
{
    my $xx = shift @ARG;
    my ($x, $y, $tmp, $ser);
    my @cof = (
        76.18009172947146,
        -86.50532032941677,
        24.01409824083091,
        -1.231739572450155,
        0.1208650973866179e-2,
        -0.5395239384953e-5
        );
    my $j;
    
    $y     = $x = $xx;
    $tmp     = $x + 5.5;
    $tmp     -= ($x+0.5)*log $tmp;
    $ser    =1.000000000190015;
    
    for($j=0; $j<=5; $j++)
    {
        $ser += $cof[$j]/++$y;
    }
    return -$tmp+log( 2.5066282746310005 * $ser / $x);
}

sub kstwo
{
    my($data1, $data2, $isSortedData) = @ARG;
    
    my $d;
    my $prob;

    my $j1    = 1;
    my $j2    = 1;

    my $d1;
    my $d2;
    my $dt;
    my $n1;
    my $n2;
    my $en1;
    my $en2;
    my $en;
    my $fn1    = 0.0;
    my $fn2    = 0.0;

    unless(defined($isSortedData) and $isSortedData)
    {
        @$data1 = sort numerically_ascend @$data1;
        @$data2 = sort numerically_ascend @$data2;
    }
    
    $en1    = $n1    = scalar(@$data1);
    $en2    = $n2    = scalar(@$data2);
    
    $d     = 0.0;
    
    while(     $j1 <= $n1
    &&     $j2 <= $n2)
    {
        $d1 = $data1->[ ($j1 - 1) ];
        $d2 = $data2->[ ($j2 - 1) ];
        if( $d1 <= $d2 )
        {
            $fn1    = $j1/$en1;
            $j1++;
        }
        if( $d2 <= $d1 )
        {
            $fn2    = $j2/$en2;
            $j2++;
        }
        $dt = abs($fn2-$fn1);
        if( $dt > $d )
        {
            $d = $dt;
        }
    }
    $en    = sqrt( $en1*$en2 / ($en1+$en2) );
    $prob    = probks( ($en + 0.12 + 0.11/$en) * $d );
    
    return ($d, $prob);
}

sub moment
#_ Given an array of data, this routine returns its mean ave,
#_ average deviation adev, standard deviation sdev, variance var,
#_ skewness skew,and kurtosis curt.
{
    my $aData = shift;

    my $ave;        # mean
    my $adev;        # average deviation
    my $sdev;        # standard deviation
    my $var;        # variance
    my $skew;        # skewness
    my $curt;        # kurtosis

    my $x;
    my $n = @$aData;
    my ($s, $p);
    my $ep = 0.0;
    
    Assert( 2 <= $n, "Number of elements must be 2 or more");
    
    #_
    #_ Get mean
    #_
    
    $s = 0;
    for $x (@$aData)
    { 
        $s += $x;
    }
    
    $ave = $s/$n;
    
    #_
    #_ Get 1st, 2nd, 3rd and 4th moments of dev from mean
    #_
    $adev = $var = $skew = $curt = 0.0;
    
    for $x (@$aData)
    {
        $s     = $x - $ave;
        $ep     += $s;
        $adev     += abs $s;
        
        $var    += $s ** 2;
        $skew    += $s ** 3;
        $curt    += $s ** 4;
    }
    
    $adev     /= $n;
    $var     = ($var - $ep ** 2 / $n) / ($n - 1);
    $sdev    = sqrt $var;
    
    Prefer(0 != $var, "No skew/kurtosis when variance = 0");
    
    $skew    /= $n * $var * $sdev;
    $curt    = $curt / ($n * $var ** 2) - 3.0;
    
    return $ave, $adev, $sdev, $var, $skew, $curt;
}

sub pearsn ($$)
#_
#_ Given two arrays, pearsn finds their correlation coefficient r,
#_ the significance level at which the null hypothesis of zero correlation
#_ is disproved (prob whose small value indicates a significant correlation),
#_ and Fisher's z, whose value can be used in furhter statistical tests.
#_
#_ NB Calculation of z and prob add 25% cpu time
#_
{
    my($aX, $aY) = @ARG;
    my $r;
    my $prob;
    my $z;
    
    my $nelem;
    my $meanX;
    my $meanY;
    
    my $i;
    my $xt;
    my $yt;
    my $numtr;
    my $denomX;
    my $denomY;

    my $df;
    my $t;
    
    Assert(@$aX == @$aY,
    "Different length arrays. Need one-to-one mapping for this function.");
    
    $nelem = @$aX;
    $meanX = Avg($aX);
    $meanY = Avg($aY);

    #_ Compute the correlation co-efficient
    
    for($i=0; $i<$nelem; $i++)
    {
        $xt = ($aX->[$i] - $meanX);
        $yt = ($aY->[$i] - $meanY);
        $numtr += $xt * $yt;
        $denomX += Sqr($xt);
        $denomY += Sqr($yt);
    }
    $r = $numtr / sqrt($denomX * $denomY);

    #_ Fisher's z tranformation

    $z = 0.5 * log((1 + $r + TINY)/(1 - $r + TINY));
        
    $df = $nelem - 2;
    
    #_ Student's T-test
    
    $t = $r * sqrt($df/((1 - $r + TINY) * (1 + $r + TINY)));
        
    #_ accurate
    $prob = betai( 0.5 * $df, 0.5, $df/($df + Sqr($t)) );
    
    #_ approx for large n
    # $prob = erfcc(abs($z * sqrt($nelem-1))/1.4142136);

    return $r, $prob, $z;
}

sub probks
{
    my($alam) = @ARG;
    
    my $j;
    my $a2;
    my $fac     = 2.0;
    my $sum     = 0.0;
    my $term;
    my $termbf     = 0.0;
    
    $a2 = -2.0 * $alam * $alam;
    
    for($j=1; $j<=100; $j++)
    {
        $term     = $fac * exp( $a2 * $j * $j );
        $sum     += $term;
        if(abs($term) <= EPS1 * $termbf
        || abs($term) <= EPS2 * $sum)
        {
            return $sum;
        }
        $fac     = -$fac;
        $termbf = abs($term);
    }
    return 1.0;
}

sub numerically_ascend    { $a <=> $b }

1;
