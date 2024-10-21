use strict;
#------------------------------------------------------------------------------
package VUtils::Protein;
use Exporter;
use English;
use Carp;
use Assert;
use StdDefs;

use base qw( Exporter );

use vars qw( @EXPORT_OK );
@EXPORT_OK = qw(
        Amino1To3
        Amino3To1
        AminoHydrophob_FP
        GetArrayAminos1
        GetArrayStdAminos1
        GetArrayStdAminos3
        AtomTypeVdwRadius
        IsAmino1
        IsAmino3
        IsKnownAtomType
        IsPolarAtomType
        IsStdAmino1
        IsStdAmino3
        );

require "dumpvar.pl";

#-----------------
# Public interface
#-----------------

sub Amino1To3($);
sub Amino3To1($);
sub GetArrayAminos1();
sub GetArrayStdAminos1();
sub GetArrayStdAminos3();
sub IsAmino1($);
sub IsStdAmino1($);
sub IsAmino3($);
sub IsStdAmino3($);

sub AminoHydrophob_FP($);
# Function:
#   Returns hydrophobicity value of amino acid taken from the scale of
#       Fauchere & Pliska (1983)
# WARNING:
#   1. URE: amino acid argument must be from the single letter code
#   2. URE: amino acid must be one of the standard 20.
# ARGUMENTS:
#   1. <char> std amino acid
# RETURN:
#   1. <real> hydrophobicity of amino acid

sub AtomTypeVdwRadius($);
sub IsKnownAtomType($);
sub IsPolarAtomType($);

#-------------
# Implemention
#-------------

# 3-letter code for standard amino acids

my %hStdAminoCodes3To1 = (
        'ALA'=>'A',    'ARG'=>'R',    'ASN'=>'N',    'ASP'=>'D',
        'CYS'=>'C',    'GLN'=>'Q',    'GLU'=>'E',    'GLY'=>'G',
        'HIS'=>'H',    'ILE'=>'I',    'LEU'=>'L',    'LYS'=>'K',
        'MET'=>'M',    'PHE'=>'F',    'PRO'=>'P',    'SER'=>'S',
        'THR'=>'T',    'TRP'=>'W',    'TYR'=>'Y',    'VAL'=>'V',
        );

my %hStdAminoCodes1To3 = reverse %hStdAminoCodes3To1;

# 3-letter code for standard & non-standard amino acids

my %hAllAminoCodes3To1 = (
        '1PA'=>'A',    'ALA'=>'A',    'ALM'=>'A',    'ALT'=>'A',
        'AYA'=>'A',    'B2A'=>'A',    'BAL'=>'A',    'DAL'=>'A',
        'HMA'=>'A',    'MAA'=>'A',    'NAL'=>'A',    'NAM'=>'A',
        'PYA'=>'A',    'ASX'=>'B',    'ALS'=>'C',    'BCS'=>'C',
        'BUC'=>'C',    'C5C'=>'C',    'C6C'=>'C',    'CAS'=>'C',
        'CCS'=>'C',    'CEA'=>'C',    'CME'=>'C',    'CSD'=>'C',
        'CSO'=>'C',    'CSP'=>'C',    'CSS'=>'C',    'CSW'=>'C',
        'CSX'=>'C',    'CYF'=>'C',    'CYG'=>'C',    'CYM'=>'C',
        'CYS'=>'C',    'EFC'=>'C',    'GT9'=>'C',    'NPH'=>'C',
        'OCS'=>'C',    'OCY'=>'C',    'PBB'=>'C',    'PEC'=>'C',
        'PR3'=>'C',    'PYX'=>'C',    'SCH'=>'C',    'SCS'=>'C',
        'SEC'=>'C',    'SHC'=>'C',    'SMC'=>'C',    'SNC'=>'C',
        'TNB'=>'C',    'ACB'=>'D',    'ASK'=>'D',    'ASP'=>'D',
        'BHD'=>'D',    'DAS'=>'D',    'DOH'=>'D',    'IAS'=>'D',
        'PPD'=>'D',    'SNN'=>'D',    'CGU'=>'E',    'GGL'=>'E',
        'GLU'=>'E',    'ILG'=>'E',    'APE'=>'F',    'B1F'=>'F',
        'B2F'=>'F',    'CHS'=>'F',    'DHP'=>'F',    'DPN'=>'F',
        'EHP'=>'F',    'FOG'=>'F',    'FRD'=>'F',    'HMF'=>'F',
        'HPH'=>'F',    'PAP'=>'F',    'PHA'=>'F',    'PHE'=>'F',
        'PHI'=>'F',    'PHL'=>'F',    'PHM'=>'F',    'PPH'=>'F',
        'PPN'=>'F',    'PSA'=>'F',    'ACY'=>'G',    'GCM'=>'G',
        'GL3'=>'G',    'GLM'=>'G',    'GLY'=>'G',    'MGY'=>'G',
        'NIP'=>'G',    'PGL'=>'G',    'PGY'=>'G',    'H2P'=>'H',
        'HIC'=>'H',    'HIP'=>'H',    'HIS'=>'H',    'MHS'=>'H',
        'B2I'=>'I',    'DCI'=>'I',    'ILE'=>'I',    'IML'=>'I',
        'BLY'=>'K',    'GPL'=>'K',    'INI'=>'K',    'KCX'=>'K',
        'LLP'=>'K',    'LLY'=>'K',    'LYM'=>'K',    'LYS'=>'K',
        'M3L'=>'K',    'MLY'=>'K',    'MLZ'=>'K',    'SLZ'=>'K',
        'BLE'=>'L',    'BNO'=>'L',    'DLE'=>'L',    'FLE'=>'L',
        'LEU'=>'L',    'MHL'=>'L',    'MLE'=>'L',    'MNL'=>'L',
        'NLE'=>'L',    'OLE'=>'L',    'PLE'=>'L',    'CXM'=>'M',
        'FME'=>'M',    'MET'=>'M',    'MHO'=>'M',    'MSE'=>'M',
        'OMT'=>'M',    'SAM'=>'M',    'SME'=>'M',    'ASN'=>'N',
        'MEN'=>'N',    '5HP'=>'P',    'DPR'=>'P',    'HYP'=>'P',
        'PRO'=>'P',    'PRS'=>'P',    'GLN'=>'Q',    'MGN'=>'Q',
        'PCA'=>'Q',    'AGM'=>'R',    'ARG'=>'R',    'ARM'=>'R',
        'HMR'=>'R',    'MAI'=>'R',    'CLB'=>'S',    'CLD'=>'S',
        'DSE'=>'S',    'MIS'=>'S',    'SBD'=>'S',    'SBL'=>'S',
        'SEP'=>'S',    'SER'=>'S',    'AEI'=>'T',    'ALO'=>'T',
        'DMT'=>'T',    'DTH'=>'T',    'TBM'=>'T',    'THC'=>'T',
        'THR'=>'T',    'TMB'=>'T',    'TMD'=>'T',    'TPO'=>'T',
        'CSE'=>'U',    'B2V'=>'V',    'DHN'=>'V',    'DVA'=>'V',
        'MNV'=>'V',    'MVA'=>'V',    'VAD'=>'V',    'VAF'=>'V',
        'VAL'=>'V',    'FTR'=>'W',    'HTR'=>'W',    'LTR'=>'W',
        'TCR'=>'W',    'TRF'=>'W',    'TRN'=>'W',    'TRO'=>'W',
        'TRP'=>'W',    'AHT'=>'Y',    'DBY'=>'Y',    'FTY'=>'Y',
        'PAQ'=>'Y',    'PTH'=>'Y',    'PTR'=>'Y',    'TPQ'=>'Y',
        'TYI'=>'Y',    'TYN'=>'Y',    'TYR'=>'Y',    'TYS'=>'Y',
        'GLX'=>'Z',
        );

my %hAllAminoCodes1 = reverse %hAllAminoCodes3To1;
for my $key (keys %hAllAminoCodes1) { $hAllAminoCodes1{$key} = true }

# Van der Waals radii for all pdb atom types

my %hAtomTypeVdwRadii = (
        ' AD1'=> 1.50,    ' AD2'=> 1.50,    ' AE1'=> 1.50,
        ' AE2'=> 1.50,    ' C  '=> 1.76,    ' C1*'=> 1.80,
        ' C1A'=> 1.78,    ' C1B'=> 1.78,    ' C1C'=> 1.78,
        ' C1D'=> 1.78,    ' C2 '=> 1.80,    ' C2*'=> 1.80,
        ' C2A'=> 1.78,    ' C2A'=> 1.80,    ' C2B'=> 1.78,
        ' C2C'=> 1.78,    ' C2D'=> 1.78,    ' C3*'=> 1.80,
        ' C3A'=> 1.78,    ' C3B'=> 1.78,    ' C3C'=> 1.78,
        ' C3D'=> 1.78,    ' C4 '=> 1.80,    ' C4*'=> 1.80,
        ' C4A'=> 1.78,    ' C4B'=> 1.78,    ' C4C'=> 1.78,
        ' C4D'=> 1.78,    ' C5 '=> 1.80,    ' C5*'=> 1.80,
        ' C5M'=> 1.80,    ' C6 '=> 1.80,    ' C8 '=> 1.80,
        ' CA '=> 1.87,    ' CAA'=> 1.90,    ' CAB'=> 1.90,
        ' CAC'=> 1.90,    ' CAD'=> 1.90,    ' CB '=> 1.87,
        ' CBA'=> 1.90,    ' CBB'=> 1.90,    ' CBC'=> 1.90,
        ' CBD'=> 1.90,    ' CD '=> 1.76,    ' CD '=> 1.87,
        ' CD1'=> 1.76,    ' CD1'=> 1.87,    ' CD2'=> 1.76,
        ' CD2'=> 1.87,    ' CE '=> 1.87,    ' CE1'=> 1.76,
        ' CE2'=> 1.76,    ' CE3'=> 1.76,    ' CG '=> 1.76,
        ' CG '=> 1.87,    ' CG1'=> 1.87,    ' CG2'=> 1.87,
        ' CGA'=> 1.90,    ' CGD'=> 1.90,    ' CH2'=> 1.76,
        ' CH3'=> 1.87,    ' CHA'=> 2.00,    ' CHB'=> 2.00,
        ' CHC'=> 2.00,    ' CHD'=> 2.00,    ' CMA'=> 1.90,
        ' CMB'=> 1.90,    ' CMC'=> 1.90,    ' CMD'=> 1.90,
        ' CZ '=> 1.76,    ' CZ2'=> 1.76,    ' CZ3'=> 1.76,
        ' N  '=> 1.65,    ' NA '=> 1.55,    ' NB '=> 1.55,
        ' NC '=> 1.55,    ' ND '=> 1.55,    ' N1 '=> 1.60,
        ' N2 '=> 1.60,    ' N3 '=> 1.60,    ' N4 '=> 1.60,
        ' N6 '=> 1.60,    ' N7 '=> 1.60,    ' N9 '=> 1.60,
        ' ND1'=> 1.65,    ' ND2'=> 1.65,    ' NE '=> 1.65,
        ' NE1'=> 1.65,    ' NE2'=> 1.65,    ' NH1'=> 1.65,
        ' NH2'=> 1.65,    ' NZ '=> 1.50,    ' O  '=> 1.40,
        ' O1A'=> 1.35,    ' O1D'=> 1.35,    ' O1P'=> 1.40,
        ' O2 '=> 1.40,    ' O2*'=> 1.40,    ' O2A'=> 1.35,
        ' O2D'=> 1.35,    ' O2P'=> 1.40,    ' O3*'=> 1.40,
        ' O4 '=> 1.40,    ' O4*'=> 1.40,    ' O5*'=> 1.40,
        ' O6 '=> 1.40,    ' OD1'=> 1.40,    ' OD2'=> 1.40,
        ' OE1'=> 1.40,    ' OE2'=> 1.40,    ' OG '=> 1.40,
        ' OG1'=> 1.40,    ' OH '=> 1.40,    ' P  '=> 1.90,
        ' SD '=> 1.85,    ' SG '=> 1.85,    ' OXT'=> 1.40,  #probably
        );    

# polarity <bool> for all pdb atom types

my %hAtomTypeIsPolar = (
        ' AD1'=> 0,    ' AD2'=> 0,    ' AE1'=> 0,    ' AE2'=> 0,
        ' C  '=> 0,    ' C1*'=> 0,    ' C1A'=> 0,    ' C1B'=> 0,
        ' C1C'=> 0,    ' C1D'=> 0,    ' C2 '=> 0,    ' C2*'=> 0,
        ' C2A'=> 0,    ' C2A'=> 0,    ' C2B'=> 0,    ' C2C'=> 0,
        ' C2D'=> 0,    ' C3*'=> 0,    ' C3A'=> 0,    ' C3B'=> 0,
        ' C3C'=> 0,    ' C3D'=> 0,    ' C4 '=> 0,    ' C4*'=> 0,
        ' C4A'=> 0,    ' C4B'=> 0,    ' C4C'=> 0,    ' C4D'=> 0,
        ' C5 '=> 0,    ' C5*'=> 0,    ' C5M'=> 0,    ' C6 '=> 0,
        ' C8 '=> 0,    ' CA '=> 0,    ' CAA'=> 0,    ' CAB'=> 0,
        ' CAC'=> 0,    ' CAD'=> 0,    ' CB '=> 0,    ' CBA'=> 0,
        ' CBB'=> 0,    ' CBC'=> 0,    ' CBD'=> 0,    ' CD '=> 0,
        ' CD '=> 0,    ' CD1'=> 0,    ' CD1'=> 0,    ' CD2'=> 0,
        ' CD2'=> 0,    ' CE '=> 0,    ' CE1'=> 0,    ' CE2'=> 0,
        ' CE3'=> 0,    ' CG '=> 0,    ' CG '=> 0,    ' CG1'=> 0,
        ' CG2'=> 0,    ' CGA'=> 0,    ' CGD'=> 0,    ' CH2'=> 0,
        ' CH3'=> 0,    ' CHA'=> 0,    ' CHB'=> 0,    ' CHC'=> 0,
        ' CHD'=> 0,    ' CMA'=> 0,    ' CMB'=> 0,    ' CMC'=> 0,
        ' CMD'=> 0,    ' CZ '=> 0,    ' CZ2'=> 0,    ' CZ3'=> 0,
        ' N  '=> 1,    ' NA '=> 1,    ' NB '=> 1,    ' NC '=> 1,
        ' ND '=> 1,    ' N1 '=> 1,    ' N2 '=> 1,    ' N3 '=> 1,
        ' N4 '=> 1,    ' N6 '=> 1,    ' N7 '=> 1,    ' N9 '=> 1,
        ' ND1'=> 1,    ' ND2'=> 1,    ' NE '=> 1,    ' NE1'=> 1,
        ' NE2'=> 1,    ' NH1'=> 1,    ' NH2'=> 1,    ' NZ '=> 1,
        ' O  '=> 1,    ' O1A'=> 1,    ' O1D'=> 1,    ' O1P'=> 1,
        ' O2 '=> 1,    ' O2*'=> 1,    ' O2A'=> 1,    ' O2D'=> 1,
        ' O2P'=> 1,    ' O3*'=> 1,    ' O4 '=> 1,    ' O4*'=> 1,
        ' O5*'=> 1,    ' O6 '=> 1,    ' OD1'=> 1,    ' OD2'=> 1,
        ' OE1'=> 1,    ' OE2'=> 1,    ' OG '=> 1,    ' OG1'=> 1,
        ' OH '=> 1,    ' P  '=> 0,    ' SD '=> 0,    ' SG '=> 0,
        ' OXT'=> 1,
        );

# hydrophobicity scale of Fauchere & Pliska (1983)

my %hAminoHydrophob_FaucherePliska = (
        'A'=>  0.31,   'R'=> -1.01,   'N'=> -0.60,   'D'=> -0.77,
        'C'=>  1.54,   'Q'=> -0.22,   'E'=> -0.64,   'G'=>  0.00,
        'H'=>  0.13,   'I'=>  1.80,   'L'=>  1.70,   'K'=> -0.99,
        'M'=>  1.23,   'F'=>  1.79,   'P'=>  0.72,   'S'=> -0.04,
        'T'=>  0.26,   'W'=>  2.25,   'Y'=>  0.96,   'V'=>  1.22,
        );

sub Amino1To3($)         { $hStdAminoCodes1To3{uc $ARG[0]} }
sub Amino3To1($)         { $hAllAminoCodes3To1{uc $ARG[0]} }
sub GetArrayAminos1()    { [keys %hAllAminoCodes1] }
sub GetArrayStdAminos1() { [keys %hStdAminoCodes1To3] }
sub GetArrayStdAminos3() { [keys %hStdAminoCodes3To1] }
sub IsAmino1($)          { exists $hAllAminoCodes1{uc $ARG[0]} }
sub IsStdAmino1($)       { exists $hStdAminoCodes1To3{uc $ARG[0]} }
sub IsAmino3($)          { exists $hAllAminoCodes3To1{uc $ARG[0]} }
sub IsStdAmino3($)       { exists $hStdAminoCodes3To1{uc $ARG[0]} }

sub AminoHydrophob_FP($) { $hAminoHydrophob_FaucherePliska{uc $ARG[0]}}

sub AtomTypeVdwRadius($) { $hAtomTypeVdwRadii{uc $ARG[0]} }
sub IsKnownAtomType($)   { exists $hAtomTypeVdwRadii{uc $ARG[0]} }
sub IsPolarAtomType($)   { $hAtomTypeIsPolar{uc $ARG[0]} }



if(not caller){Run()}

sub Run(){print "void run()\n"}

true;
