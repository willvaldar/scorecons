# Scorecons
Scoring residue conservation from amino acid multiple sequence alignments

Scorecons is a program that quantifies residue conservation in a multiple sequence alignment. Given a multiple sequence alignment file, Scorecons calculates the degree of amino acid variability in each column of the alignment and returns this information to the user. Read more about the different scores used in the paper:
Valdar WSJ (2002). Scoring residue conservation. Proteins: Structure, Function, and Genetics. 43(2): 227-241.

Scorecons has been maintained as a web server at https://www.ebi.ac.uk/thornton-srv/databases/cgi-bin/valdar/scorecons_server.pl

This repo provides the original perl program behind that web server.

To run the program:
1. Set the environmental variable SCORECONS_MATRICES to the matrix/ directory. Eg, in bash

`export SCORECONS_MATRICES "/usr/myname/otherthings/scorecons/matrix/"`
   
2. Run
   
`perl -w -I<pathto_include_directory> scorecons <filename>`
   
An example fasta file is provided.
