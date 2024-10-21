use strict;
#==============================================================================
# CLASS: CSequenceReader
#=======================
# DESCRIPTION:
#

#_ Class declaration

package CSequenceReader;

#_ Include libraries

use English;
use StdDefs;
use Assert;
use CSequence;
use String;

#------------------------------------------------------------------------------
# INTERFACE
#----------

#_ Public class constants

use constant CORA   => 'CSequenceReader::CORA';
use constant FASTA  => 'CSequenceReader::FASTA';
use constant PIR    => 'CSequenceReader::PIR';
use constant SELEX  => 'CSequenceReader::SELEX';
use constant FASTA_OR_PIR => 'CSequenceReader::FASTA_OR_PIR';

#_ Constructor

sub new($$$);
# Constructor
# WARNING:
#   CRE if format is not one of the class constants
# ARGUMENTS:
#   1. class
#   2. <ist> input stream
#   3. <CONSTANT> format
# RETURN:
#   1. this

#_ Public instance methods

sub getSeqs($);
# Method: reader
# RETURN:
#   <\@ CSequence> array of sequences 

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#_ Constructor

sub new ($$$)
{
    my($class, $ist, $format) = @ARG;
    
    Assert(($format eq CORA
            || $format eq FASTA
            || $format eq PIR
            || $format eq SELEX
            || $format eq FASTA_OR_PIR), "unsupported format: $format");
    
    my $this = {
            'format'=> $format,
            'ist'   => $ist,
            };
    return bless $this, $class;
}

#_ Public instance methods

sub getSeqs($)
{
    my $this = shift;
    
    return _ReadCora($this->{'ist'})  if CORA eq $this->{'format'};
    return _ReadFastaOrPir($this->{'ist'}) if FASTA eq $this->{'format'};
    return _ReadFastaOrPir($this->{'ist'})   if PIR eq $this->{'format'};
    return _ReadSelex($this->{'ist'}) if SELEX eq $this->{'format'};
    return _ReadFastaOrPir($this->{'ist'}) 
            if FASTA_OR_PIR eq $this->{'format'};
}
            

#_ Private class methods

sub _ReadFastaOrPir($)
{
    my $ist = shift;

    my $aSeqs = [];
    
    my $BEFORE_SEQS = -1;
    my $i = $BEFORE_SEQS;
    while (my $line = $ist->getline)
    {
        if ($line =~ m/^>/)
        {
            #------------
            # is a header
            #------------
            $i++;
            # remove header sign
            $line =~ s/^>//;
            # remove extra white space
            $line = String::Trim($line);
            $aSeqs->[$i] = new CSequence($line,null);
        }
        else
        {
            #----------------------
            # is part of a sequence
            #----------------------
            if ($BEFORE_SEQS < $i)
            {
                # remove PIR stars
                $line =~ s/\*//g;
                # swap gaps to std format
                my $gapChar = CSequence::GAP_CHAR;
                $line =~ s/[\.\-]/$gapChar/og;
                # remove extra white space
                $line = String::Trim($line);
                $aSeqs->[$i]->setSeqStr($aSeqs->[$i]->getSeqStr.$line);
            }
        }
    }
    return $aSeqs;
}

sub _ReadCora($)
{
    my $ist = shift;
    
    # skip comments and numSeqs line
    while ($ist->getline =~ m/^\#/){}
    
    # get sequence names
    my(@aSeqNames) = split m/\s+/, String::Trim($ist->getline);
    my $nSeqs = @aSeqNames;
    
    # skip line
    $ist->getline;
    
    my $aaSeqAminos = [];
    while (my $line = $ist->getline)
    {
        if ($line =~ m/\S/ and not $line =~ m/^\#/)
        {
            my $i = -1; # skip first triplet
            # parse a triplet at a time
            while ($line =~ m/((?:\s+\S+){3})/g)
            {
                if ($i >= 0 and $i < $nSeqs)
                {
                    # get juicy middle value
                    $1 =~ m/\S\s+(\S+)\s+\S/;
                    push @{$aaSeqAminos->[$i]}, $1;
                }
                $i++;
            }
        }
    }
    
    # make sequence objects
    my $aSeqs = [];
    for (my $i=0; $i<$nSeqs; $i++)
    {
        my $seqString = join '', @{$aaSeqAminos->[$i]};
        my $gapChar = CSequence::GAP_CHAR;
        $seqString =~ s/0/$gapChar/go;
        my $seq = new CSequence($aSeqNames[$i], $seqString);
        push @$aSeqs, $seq;
    }
    return $aSeqs;
}

    
sub _ReadSelex ($)
{
    my $fhIn    = shift @ARG;

    my $aSeqObjects = [];
    my @aHeaders     = ();
    my @aSeqs     = ();
    
    while($fhIn->getline !~ m/^\#\=AU/){}
    
    while($fhIn->getline =~ m/^\#\=SQ\s(\S+)\s/)
    {
        push @aHeaders, $1;
    }

    while(my $line = $fhIn->getline)
    {
        if($line =~ m/^\#\=RF/)
        {
            my $i = 0;
            while($fhIn->getline =~ m/^(\S+)\s+(\S+)$/)
            {
                my $header = $1;
                my $seq    = uc $2;
                $seq    =~ s/\./-/g;
                Assert($header eq $aHeaders[$i], "Headers don't match!!");
                if(defined $aSeqs[$i])
                {
                    $aSeqs[$i] .= $seq;
                }
                else
                {
                    $aSeqs[$i] = $seq;
                }
                $i++;
            }
        }
    }
    
    for(my $i=0; $i<@aSeqs; $i++)
    {
        push @$aSeqObjects, new CSequence( $aHeaders[$i], $aSeqs[$i] );
    }
    
    return $aSeqObjects;
}

#====
# END
#==============================================================================
true;

__END__

=head1 Class

CSequenceReader

=head1 Affiliation

Reads objects of type CSequence from stream. Often used with CSequenceWriter.

=head1 Description

An object of this class reads sequences of  a specified sequence format from a stream.
Eg, a simple pir to fasta format converter:

 use strict;
 use CSequenceWriter;
 use CSequenceReader;
 use FileIoHelper qw(GetStdOut GetStdIn);


 my $reader = new CSequenceReader(GetStdIn(), CSequenceReader::PIR);
 my $writer = new CSequenceWriter(GetStdOut(), CSequenceWriter::FASTA);
 $writer->print($reader->getSeqs);

=head1 Class constants

=over

=item CSequenceWriter::CORA

=item CSequenceWriter::FASTA

=item CSequenceWriter::PIR

=item CSequenceWriter::SELEX

=back

=head1 Methods

=over

=item new

 Constructor
 WARNING:
   CRE if format is not one of the class constants
 ARGUMENTS:
   1. class
   2. <ist> input stream
   3. <CONSTANT> format
 RETURN:
   1. this

=item getSeqs

 Method: reader
 RETURN:
   <\@ CSequence> array of sequences 

