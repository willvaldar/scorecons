use strict;
#==============================================================================
# CLASS: CSequence
#=================
# DESCRIPTION: Basic sequence class. Optimized for low memory consumption.
#

#_ Class declaration
package CSequence;

#_ Include libraries
use English;
use StdDefs;
use VarType qw(IsArrayRef);

#------------------------------------------------------------------------------
# INTERFACE
#----------

#_ Public class constants
use constant GAP_CHAR => '-';

#_ Constructor

sub new($$$);
# Constructor
# ARGUMENTS:
#   1. class
#   2. <string> header
#   3. <string> sequence  OR  <\@ char> sequence>
# RETURN:
#   1. this

#_ Public instance methods

sub clone($);
# Method: copy constructor
# DESCRIPTION: returns copy of object
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <CSequence> copy

sub equals($$);
# Method: comparator
# DESCRIPTION: returns true iff the argument CSequence shares both the header
#   and the gapped sequence of this.
# ARGUMENTS:
#   1. this
#   2. <CSequence> other
# RETURN:
#   1. <bool> are equal

sub sequenceEquals($$);
# Method: comparator
# DESCRIPTION: returns true iff the argument CSequence shares the gapped
#   sequence of this.
# ARGUMENTS:
#   1. this
#   2. <CSequence> other
# RETURN:
#   1. <bool> sequences are equal

sub fillToLength; # $$ or $$$
# Method: modifier
# DESCRIPTION: pads the sequence to the desired length with the specified
#   $char. $char is GAP_CHAR by default.
# WARNING:
#   1. CRE if $char is not a single character
# ARGUMENTS:
#   1. this
#   2. <int> new length
#   3. <char> filler character = GAP_CHAR
# RETURN:
#   1. this

sub getHeader($);
# Method: accessor
# DESCRIPTION: returns the header string
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <string> header
 
#sub getHeaderRef($);
# Method: optimized accessor
# DESCRIPTION: returns a reference to the header string. Intended for efficient
#   communication of long header info.
# WARNING:
#   1. Potential URE. Value returned is part of the object's internal state
#   and should not be modified
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <\$ string> header

sub getLength($);
# Method: accessor
# DESCRIPTION: returns the length of the sequence including gap chars
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <int> length

sub getLengthNoGaps($);
# Method: accessor
# DESCRIPTION: returns the length of the sequence excluding gap chars
# ARGUMENTS:
#   1. this
# RETURN:
#  1. <int> length

sub getResidue($$);
# Method: accessor
# DESCRIPTION: returns the residue at position $i (range 0..length-1)
# WARNING:
#   1. URE if $i > length-1
# ARGUMENTS:
#   1. this
#   2. <int> pos (0..n-1)
# RETURN:
#   1. <char> residue

sub getResidueNoGaps($$);
# Method: accessor
# DESCRIPTION: returns the ($i-1)th non gap residue
# WARNING:
#   1. URE if $i > length-1
# ARGUMENTS:
#   1. this
#   2. <int> pos (0..n-1)
# RETURN:
#   1. <char> residue

sub getResidues($);
# Method: accessor
# DESCRIPTION: returns the sequence as an array
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <\@ chars> sequence

sub getSeqStr($);
# Method: accessor
# DESCRIPTION: returns the sequence as a string
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <string> sequence

sub getSeqStrRef($);
# optimized accessor
# DESCRIPTION: returns a reference to the sequence string. Intended for
#   efficient communication of long sequence info.
# WARNING:
#   1. Potential URE. Value returned is part of the object's internal state
#   and should not be modified
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <\$ string> sequence

sub hasBackGaps($);
sub hasExternalGaps($);
sub hasFrontGaps($);
sub hasGaps($);
sub hasInternalGaps($);
# Methods: descriptors
# DESCRIPTION: returns whether the sequence contains gaps:
#   back: after the last non gap residue (=amino)
#   external: before the first amino or after the last amino
#   front: before the first amino acid
#   internal: after the first amino but before the last amino
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <bool> has gaps

sub hasResidueType($$);
# Method: accessor
# DESCRIPTION: returns whether the specified char is present in the sequence
# ARGUMENTS:
#   1. this
#   2. <char> residue type
# RETURN:
#   1. <bool>

sub hasSubSequence($$);
# Method: accessor
# DESCRIPTION: returns whether the specified substring is present in the
#   sequence
# ARGUMENTS:
#   1. this
#   2. <string> subsequence
# RETURN:
#   1. <bool>

sub pushFront($$);
sub pushBack($$);
# Method: modifier
# DESCRIPTION: adds residues to either the front or back of the sequence
# ARGUMENTS:
#   1. this
#   2. <string> residues  OR  <\@ chars> residues OR <CSequence> seq
# RETURN:
#   1. this

sub removeBackGaps($);
sub removeFrontGaps($);
sub removeExternalGaps($);
sub removeGaps($);
sub removeInternalGaps($);
# Methods: modifiers
# DESCRIPTION: removes gaps from:
#   back: after the last non gap residue (=amino)
#   external: before the first amino or after the last amino
#   front: before the first amino acid
#   internal: after the first amino but before the last amino
# ARGUMENTS:
#   1. this
# RETURN:
#   1. this

sub setHeader($$);
# Method: accessor
# DESCRIPTION: set the header for the sequence
# ARGUMENTS:
#   1. this
#   2. <string> header
# RETURN:
#   void

sub setResidues($$);
# Method: accessor
# DESCRIPTION: set the sequence as an array of residues
# ARGUMENTS:
#   1. this
#   2. <\@ char> residues
# RETURN:
#   void

sub setSeqStr($$);
# Method: accessor
# DESCRIPTION: set the sequence as a string
# ARGUMENTS:
#   1. this
#   2. <string> sequence
# RETURN:
#   void

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#_ Class constants
use constant GapChar => '-';    # for backwards compatibility


#_ Constructor

sub new ($$$)
{
    my ($class, $header, $seq) = @ARG;
    my $this = {
        'header'=> $header,
        'seq'   => IsArrayRef($seq) ? join('', @$seq) : $seq,
        };
    return bless $this, $class;
}

#_ Public instance methods


sub clone($)
{    
    my $this = shift;
    return new CSequence($this->{'header'}, $this->{'seq'});
}

sub equals($$)
{
    my($this, $other) = shift;
    
    return $this->{'header'} eq $other->{'header'}
            && $this->{'seq'} eq $other->{'seq'};
}

sub sequenceEquals($$) {$ARG[0]->{'seq'} eq $ARG[1]->{'seq'}}

sub fillToLength
{
    2 == @ARG or 3 == @ARG or WrongNumArgsError();
    
    my($this, $newLength) = @ARG;
    my $fillChar = $ARG[2] || GAP_CHAR;
    
    1 == length($fillChar) or Fatal("filler must be one char only");
    
    my $nGaps = $newLength - length $this->{'seq'};
    
    0 <= $nGaps or Fatal("gap fill cannot be negative");
    
    $this->{'seq'} .= $fillChar x $nGaps;
    return $this;
}

sub getHeader($)     { $ARG[0]->{'header'} }

sub getHeaderRef($)  { \($ARG[0]->{'header'}) }

sub getLength($)     { length $ARG[0]->{'seq'} }

sub getLengthNoGaps($)
{
    my $this = shift;
    return $this->clone->removeGaps->getLength;
}

sub getRange($$$)
{
    my($seq, $pos, $n) = @ARG;
    my $subSeq = $seq->clone;
    $subSeq->{'seq'} = substr($subSeq->{'seq'}, $pos, $n);
    return $subSeq;
}

sub getResidue($$)
{
    my($this, $i) = @ARG;
    return substr($this->{'seq'}, $i, 1);
}

sub getResidueNoGaps($$)
{
    my($this, $i) = @ARG;
    return $this->clone->removeGaps->getResidue($i);
}

sub getResidues($)   { [split m//, $ARG[0]->{'seq'}] }

sub getSeqStr($)     { $ARG[0]->{'seq'} }

sub getSeqStrRef($)  { \($ARG[0]->{'seq'}) }

sub hasBackGaps($)      {$ARG[0]->{'seq'} =~ m/-$/}

sub hasExternalGaps($)
{
    $ARG[0]->{'seq'} =~ m/^-/ || $ARG[0]->{'seq'} =~ m/-$/;
}

sub hasFrontGaps($)     {$ARG[0]->{'seq'} =~ m/^-/}

sub hasGaps($)          {$ARG[0]->{'seq'} =~ m/-/}

sub hasInternalGaps($)
{
    my $this = shift;
    return $this->clone->removeExternalGaps->hasGaps;
}

sub hasResidueType($$)
{
    my($this, $residueSymbol) = @ARG;
    
    return -1 != index($this->{'seq'}, $residueSymbol);
}

sub hasSubSequence($$)
{
    my($this, $subSeq) = @ARG;
    
    return -1 != index($this->{'seq'}, $subSeq);
}

sub pushFront($$)
{
    my($this, $subSeq) = @ARG;
    
    if (IsArrayRef($subSeq))
    {
        $subSeq = join('',@$subSeq);
    }
    $this->{'seq'} = $subSeq . $this->{'seq'};
    return $this;
}
    
sub pushBack($$)
{
    my($this, $subSeq) = @ARG;
    
    if (IsArrayRef($subSeq))
    {
        $this->pushBack(join('',@$subSeq));
    }
    elsif(ref($subSeq) =~ m/CSequence/)
    {
        $this->pushBack($subSeq->getSeqStr);
    }
    else
    {
        $this->{'seq'} .= $subSeq;
    }
    return $this;
}   

sub removeBackGaps($)
{
    my $this = shift;
    $this->{'seq'} =~ s/-+$//;
    return $this;
}

sub removeExternalGaps($)
{
    my $this = shift;
    return $this->removeBackGaps->removeFrontGaps;
}

sub removeFrontGaps($)
{
    my $this = shift;
    $this->{'seq'} =~ s/^-+//;
    return $this;
}

sub removeGaps($)
{
    my $this = shift;
    $this->{'seq'} =~ s/-//g;
    return $this;
}

sub removeInternalGaps($)
{
    my $this = shift;
    $this->{'seq'} =~ s/^(-*)//;
    my $frontGaps = $1;
    $this->{'seq'} =~ s/(-*)$//;
    my $backGaps = $1;
    $this->{'seq'} =~ s/-//g;
    $this->{'seq'} = $frontGaps . $this->{'seq'} . $backGaps;
    return $this;
}
    
sub setHeader($$)    { $ARG[0]->{'header'} = $ARG[1] }

sub setResidues($$)
{
    my($this, $aResidues) = @ARG;
    $this->{'seq'} = join('',@$aResidues);
}
    
sub setSeqStr($$)    { $ARG[0]->{'seq'} = $ARG[1] }

sub gapFillToLength ($$)
{
    return $ARG[0]->fillToLength($ARG[1]);
}

#====
# END
#==============================================================================
true;
__END__

=head1 Class

CSequence

=head1 Description

Basic sequence class. Optimized for low memory consumption.

=head1 Class constants

=over

=item CSequence::GAP_CHAR

 Character representing a gap

=back

=head1 Methods

=over

=item new

 Constructor
 ARGUMENTS:
   1. class
   2. <string> header
   3. <string> sequence  OR  <\@ char> sequence>
 RETURN:
   1. this

=item clone

 Method: copy constructor
 DESCRIPTION: returns copy of object
 ARGUMENTS:
   1. this
 RETURN:
   1. <CSequence> copy

=item equals

 Method: comparator
 DESCRIPTION: returns true iff the argument CSequence shares both the header
   and the gapped sequence of this.
 ARGUMENTS:
   1. this
   2. <CSequence> other
 RETURN:
   1. <bool> are equal

=item sequenceEquals

 Method: comparator
 DESCRIPTION: returns true iff the argument CSequence shares the gapped
   sequence of this.
 ARGUMENTS:
   1. this
   2. <CSequence> other
 RETURN:
   1. <bool> sequences are equal

=item fillToLength

 Method: modifier
 DESCRIPTION: pads the sequence to the desired length with the specified
   $char. $char is GAP_CHAR by default.
 WARNING:
   1. CRE if $char is not a single character
 ARGUMENTS:
   1. this
   2. <int> new length
   3. <char> filler character = GAP_CHAR
 RETURN:
   1. this

=item getHeader

 Method: accessor
 DESCRIPTION: returns the header string
 ARGUMENTS:
   1. this
 RETURN:
   1. <string> header

=item getLength

 Method: accessor
 DESCRIPTION: returns the length of the sequence including gap chars
 ARGUMENTS:
   1. this
 RETURN:
   1. <int> length

=item getLengthNoGaps

 Method: accessor
 DESCRIPTION: returns the length of the sequence excluding gap chars
 ARGUMENTS:
   1. this
 RETURN:
  1. <int> length

=item getResidue

 Method: accessor
 DESCRIPTION: returns the residue at position $i (range 0..length-1)
 WARNING:
   1. URE if $i > length-1
 ARGUMENTS:
   1. this
   2. <int> pos (0..n-1)
 RETURN:
   1. <char> residue

=item getResidueNoGaps

 Method: accessor
 DESCRIPTION: returns the ($i-1)th non gap residue
 WARNING:
   1. URE if $i > length-1
 ARGUMENTS:
   1. this
   2. <int> pos (0..n-1)
 RETURN:
   1. <char> residue

=item getResidues

 Method: accessor
 DESCRIPTION: returns the sequence as an array
 ARGUMENTS:
   1. this
 RETURN:
   1. <\@ chars> sequence

=item getSeqStr

 Method: accessor
 DESCRIPTION: returns the sequence as a string
 ARGUMENTS:
   1. this
 RETURN:
   1. <string> sequence

=item getSeqStrRef

 optimized accessor
 DESCRIPTION: returns a reference to the sequence string. Intended for
   efficient communication of long sequence info.
 WARNING:
   1. Potential URE. Value returned is part of the object's internal state
   and should not be modified
 ARGUMENTS:
   1. this
 RETURN:
   1. <\$ string> sequence

=item hasBackGaps


=item hasExternalGaps


=item hasFrontGaps


=item hasGaps


=item hasInternalGaps

 Methods: descriptors
 DESCRIPTION: returns whether the sequence contains gaps:
   back: after the last non gap residue (=amino)
   external: before the first amino or after the last amino
   front: before the first amino acid
   internal: after the first amino but before the last amino
 ARGUMENTS:
   1. this
 RETURN:
   1. <bool> has gaps

=item hasResidueType

 Method: accessor
 DESCRIPTION: returns whether the specified char is present in the sequence
 ARGUMENTS:
   1. this
   2. <char> residue type
 RETURN:
   1. <bool>

=item hasSubSequence

 Method: accessor
 DESCRIPTION: returns whether the specified substring is present in the
   sequence
 ARGUMENTS:
   1. this
   2. <string> subsequence
 RETURN:
   1. <bool>

=item pushFront


=item pushBack

 Method: modifier
 DESCRIPTION: adds residues to either the front or back of the sequence
 ARGUMENTS:
   1. this
   2. <string> residues  OR  <\@ chars> residues OR <CSequence> seq
 RETURN:
   1. this

=item removeBackGaps


=item removeFrontGaps


=item removeExternalGaps


=item removeGaps

=item removeInternalGaps

 Methods: modifiers
 DESCRIPTION: removes gaps from:
   back: after the last non gap residue (=amino)
   external: before the first amino or after the last amino
   front: before the first amino acid
   internal: after the first amino but before the last amino
 ARGUMENTS:
   1. this
 RETURN:
   1. this

=item setHeader

 Method: accessor
 DESCRIPTION: set the header for the sequence
 ARGUMENTS:
   1. this
   2. <string> header
 RETURN:
   void

=item setResidues

 Method: accessor
 DESCRIPTION: set the sequence as an array of residues
 ARGUMENTS:
   1. this
   2. <\@ char> residues
 RETURN:
   void

=item setSeqStr

 Method: accessor
 DESCRIPTION: set the sequence as a string
 ARGUMENTS:
   1. this
   2. <string> sequence
 RETURN:
   void
