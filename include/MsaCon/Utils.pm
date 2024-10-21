use strict;
#==============================================================================
# MODULE: MsaCon::Utils
#======================
# DESCRIPTION:
#

#_ Module declaration

package MsaCon::Utils;

#_ Include libraries

use English;
use StdDefs;
use Array;
use Algorithm qw(Transform);
use VUtils::Math qw(Shannon LogBase);

#_ Export

use Exporter;
use base ('Exporter');
use vars ('@EXPORT_OK');
@EXPORT_OK = qw(
        DiversityOfSymbols
        Dops);

#------------------------------------------------------------------------------
# INTERFACE
#----------

#_ Public constants

#_ Public functions

sub DiversityOfSymbols($);
# Function:
#   Calculates Shannon's entropy for an array of symbols (=numbers, strings,
#       etc).
# ARGUMENTS:
#   1. <\@ SCALAR>
# RETURN:
#   1. <real> raw entropy
#   2. <real> maximum possible entropy for that many symbols

sub Dops($);
# Function: convenience
#   Calculates the Diversity Of Position Scores, after Doss
#       (Valdar & Thornton, 2001). This is the DiversityOfSymbols expressed
#       as a fraction.
# ARGUMENTS:
#   1. <\@ SCALAR>
# RETURN:
#   1. <real: [0,1]> diversity of symbols
# SEE ALSO:
#   DiversityOfSymbols()

sub MethodName($$);
# Function: accessor
# PRECONDITION:
# WARNING:
# ARGUMENTS:
# RETURN:
# SEE ALSO:

#_ Private functions

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#_ Module variables

#_ Module init

#_ Public functions

sub DiversityOfSymbols($)
{
    my $aSym = shift;
    my $nSym = Array::Length($aSym);
    my $obsShan = Shannon(Transform(
            [values %{Array::ElementFrequencies($aSym)}], [],
            sub{$ARG[0]/$nSym}));
    my $maxShan = - LogBase(2, 1/$nSym);
    
    return $obsShan, $maxShan;
}

sub Dops($)
{
    my($obs, $max) = DiversityOfSymbols($ARG[0]);
    return $obs/$max;
}

#_ Private functions

#====
# END
#==============================================================================
true;
__END__

=head1 Module

MsaCon::Utils

=head1 Description

Miscellaneous functions for assessing residue conservation

=head1 Functions

=over

=item DiversityOfSymbols

 Function:
   Calculates Shannon's entropy for an array of symbols (=numbers, strings,
       etc).
 ARGUMENTS:
   1. <\@ SCALAR>
 RETURN:
   1. <real> raw entropy
   2. <real> maximum possible entropy for that many symbols

=item Dops

 Function: convenience
   Calculates the Diversity Of Position Scores, after Doss
       (Valdar & Thornton, 2001). This is the DiversityOfSymbols expressed
       as a fraction.
 ARGUMENTS:
   1. <\@ SCALAR>
 RETURN:
   1. <real: [0,1]> diversity of symbols
 SEE ALSO:
   DiversityOfSymbols() 
   
