use strict;
#==============================================================================
# CLASS: CAlignment
#==================
# DESCRIPTION:
#

#_ Class declaration
package CAlignment;

#_ Include libraries
use English;
use StdDefs;
use Assert;
use Algorithm qw(Transform);
use Array2d;

#------------------------------------------------------------------------------
# INTERFACE
#----------

#_ Constructor

sub new($$);
# Constructor
# DESCRIPTION: Constructs an alignment from an array of CSequence objects.
#   Gaps are used to pad trailing portions of any sequence. CSequences are
#   copied.
# ARGUMENTS:
#   1. class
#   2. const <\@ CSequence>
# RETURN:
#   1. this

#_ Public instance methods

sub getColumnResidues($$);
# Method: accessor
# DESCRIPTION: Gets all residues in the specified column
# WARNING:
#   1. URE if column does not exist
# ARGUMENTS:
#   1. this
#   2. <int> column number
# RETURN:
#   1. const <\@ char> residues

sub getLength($);
# Method: accessor
# DESCRIPTION: Returns the number of positions in the alignment.
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <int> length

sub getNumSeqs($);
# Method: accessor
# DESCRIPTION: Returns the number of sequences in the alignment
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <int> number of sequences

sub getResidueAt($$$);
# Method: accessor
# DESCRIPTION: Returns the amino acid or gap at the specified position.
#   Gap is represented as CSequence::GapChar
# WARNING:
#   1. URE if position does not exist
# ARGUMENTS:
#   1. this
#   2. <int> sequence number
#   3. <int> position number
# RETURN:
#   1. <char> amino acid or gap

sub getSeq($$);
# Method: accessor
# DESCRIPTION: Gets the specified sequence
# WARNING:
#   1. URE if no such sequence
# ARGUMENTS:
#   1. this
#   2. <int> sequence number
# RETURN:
#   1. <CSequence> sequence

sub getSeqResidues($$);
# Method: accessor
# DESCRIPTION: Returns the amino acids and gaps belonging to the specified
#   sequence.
# WARNING:
#   1. URE if sequence does not exist
# ARGUMENTS:
#   1. this
#   2. <int> sequence number
# RETURN:
#   1. <\@ char> amino acids and gaps

sub getSeqs($);
# Method: accessor
# DESCRIPTION: Gets all sequences in the alignment.
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <\@ CSequence> all sequences

sub clone($);
# Method: copy
# DESCRIPTION: Returns a complete copy of this.
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <CAlignment> copy

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#_ Constructor

sub new($$)
{
    my($class, $aSeqs) = @ARG;
    my $this = {
            'seqs'      => null,
            'numSeqs'   => 0,
            'length'    => 0,
            'alnRows'   => null,
            'alnColumns'=> null,
            };
    bless $this, $class;
    $this->_init($aSeqs);
    return $this;
}

#_ Public instance methods

sub getColumnResidues($$)
{
    my($this, $col) = @ARG;
    
    return $this->{'alnColumns'}[$col];
}

sub getLength($)
{
    return $ARG[0]->{'length'};
}

sub getNumSeqs($)
{
    return $ARG[0]->{'numSeqs'};
}

sub getResidueAt($$$)
{
    my($this, $row, $col) = @ARG;
    
    return $this->{'alnRows'}[$row][$col];
}

sub getSeq($$)
{
    my($this, $row) = @ARG;
    
    return $this->{'seqs'}[$row];
}

sub getSeqResidues($$)
{
    my($this, $row) = @ARG;
    
    return $this->{'alnRows'}[$row];
}

sub getSeqs($)
{
    return $ARG[0]->{'seqs'};
}

sub clone($)
{
    my $this = shift;
    return new CAlignment($this->{'seqs'});
}

#_ Private instance methods

sub _init($)
{
    my($this, $aOrigSeqs) = @ARG;
    
    $this->{'numSeqs'} = scalar(@$aOrigSeqs);
    # copy original sequences
    $this->{'seqs'} = Transform($aOrigSeqs, [], sub{$ARG[0]->clone});
    
    # find longest sequence
    my $maxLength = 0;
    for my $seq (@{$this->{'seqs'}})
    {
        my $length = $seq->getLength;
        if ($length > $maxLength)
        {
            $maxLength = $length;
        }
    }
    $this->{'length'} = $maxLength;
    
    # pad out all sequences to the same length
    for my $seq (@{$this->{'seqs'}})
    {
        $seq->fillToLength($maxLength);
    }
    
    # make separate arrays of rows and columns
    $this->{'alnRows'} = Transform($this->{'seqs'}, [],
            sub{$ARG[0]->getResidues});
    $this->{'alnColumns'} = Array2d::SwapAxes($this->{'alnRows'});
}
    
#====
# END
#==============================================================================

true;

__END__


=head1 Class

CAlignment

=head1 Affiliation

Contains CSequence objects

=head1 Description

An object of this class represents a multiple alignment. It allows straightforward access to column and row information.

=over

=item new

 Constructor
 DESCRIPTION: Constructs an alignment from an array of CSequence objects.
   Gaps are used to pad trailing portions of any sequence. CSequences are
   copied.
 ARGUMENTS:
   1. class
   2. const <\@ CSequence>
 RETURN:
   1. this

=item getColumnResidues

 Method: accessor
 DESCRIPTION: Gets all residues in the specified column
 WARNING:
   1. URE if column does not exist
 ARGUMENTS:
   1. this
   2. <int> column number
 RETURN:
   1. const <\@ char> residues

=item getLength

 Method: accessor
 DESCRIPTION: Returns the number of positions in the alignment.
 ARGUMENTS:
   1. this
 RETURN:
   1. <int> length

=item getNumSeqs

 Method: accessor
 DESCRIPTION: Returns the number of sequences in the alignment
 ARGUMENTS:
   1. this
 RETURN:
   1. <int> number of sequences

=item getResidueAt

 Method: accessor
 DESCRIPTION: Returns the amino acid or gap at the specified position.
   Gap is represented as CSequence::GapChar
 WARNING:
   1. URE if position does not exist
 ARGUMENTS:
   1. this
   2. <int> sequence number
   3. <int> position number
 RETURN:
   1. <char> amino acid or gap

=item getSeq

 Method: accessor
 DESCRIPTION: Gets the specified sequence
 WARNING:
   1. URE if no such sequence
 ARGUMENTS:
   1. this
   2. <int> sequence number
 RETURN:
   1. <CSequence> sequence

=item getSeqResidues

 Method: accessor
 DESCRIPTION: Returns the amino acids and gaps belonging to the specified
   sequence.
 WARNING:
   1. URE if sequence does not exist
 ARGUMENTS:
   1. this
   2. <int> sequence number
 RETURN:
   1. <\@ char> amino acids and gaps

=item getSeqs

 Method: accessor
 DESCRIPTION: Gets all sequences in the alignment.
 ARGUMENTS:
   1. this
 RETURN:
   1. <\@ CSequence> all sequences

=item clone

 Method: copy
 DESCRIPTION: Returns a complete copy of this.
 ARGUMENTS:
   1. this
 RETURN:
   1. <CAlignment> copy
