#!/bin/bash

echo  motifexs.bat - Examples for TEXTURE MOTIFS/IN
echo infile: marimba.aiff \(0.99 sec\)
echo note data files: ndfmot1.txt, ndfmot2.txt
echo breakpoint files: none

echo  A Endrich - last updated: 13 November 2000 

echo ... ndf outdur packing scatter tgrid
echo snd1st sndlast ming maxg minp maxp
echo phgrid grpspace gpsprange amprise contour multlo multhi
echo [-aatten -pposition -sspread -rseed -w -d -i]

echo 

echo set CDP_SOUND_EXT.aiff
set CDP_SOUND_EXT.aiff
echo 

echo EXAMPLE 1 - Mode 5 - a defined motif plays on pitches randomly 
echo	selected from a pitch range
echo ndfmot1.txt
echo 60
echo \#10				\(motif\)
echo 0.0 1 60 70 0.3
echo 0.1 1 61 50 0.3
echo 0.2 1 66 50 0.3
echo 0.3 1 67 50 0.3
echo 0.4 1 66 70 0.3
echo 0.5 1 67 60 0.3
echo 0.6 1 70 60 0.3
echo 0.7 1 66 60 0.3
echo 0.8 1 72 80 0.3
echo 0.9 1 66 50 0.3
echo 

echo texture motifs 5 marimba motifex1 ndfmot1.txt 12 1 0 0 1 1 30 90 48 84 0 1 1 0 0 1 1
texture motifs 5 marimba motifex1 ndfmot1.txt 12 1 0 0 1 1 30 90 48 84 0 1 1 0 0 1 1
echo 

echo 

echo EXAMPLE 2a/b/c - Mode 3 - a defined motif plays on a random selection from 
echo	the notes of a defined harmonic set at varying tempos.  Hear what 
echo	happens with the \'b\' version \(MOTIFSIN\) of the same parameters.  
echo	The \'c\' version creates overlaps with a skiptime of 0.25.
echo ndfmot2.txt
echo 60
echo \#9				\(Harmonic Field/Set\)
echo 0.0 1 60 0 0
echo 0.0 1 61 0 0
echo 0.0 1 63 0 0
echo 0.0 1 64 0 0
echo 0.0 1 66 0 0
echo 0.0 1 67 0 0
echo 0.0 1 68 0 0
echo 0.0 1 70 0 0
echo 0.0 1 72 0 0
echo \#10				\(motif\)
echo 0.0 1 60 70 0.3
echo 0.1 1 61 50 0.3
echo 0.2 1 66 50 0.3
echo 0.3 1 67 50 0.3
echo 0.4 1 66 50 0.3
echo 0.5 1 67 70 0.3
echo 0.6 1 70 50 0.3
echo 0.7 1 66 50 0.3
echo 0.8 1 72 80 0.3
echo 0.9 1 66 60 0.3
echo 

echo texture motifs   3 marimba motifex2a ndfmot2.txt 12 1    0 0 1 1 30 90 48 84 0 1 1 0 0 0.5 2
texture motifs   3 marimba motifex2a ndfmot2.txt 12 1    0 0 1 1 30 90 48 84 0 1 1 0 0 0.5 2
echo texture motifsin 3 marimba motifex2b ndfmot2.txt 12 1    0 0 1 1 30 90 48 84 0 1 1 0 0 0.5 2
texture motifsin 3 marimba motifex2b ndfmot2.txt 12 1    0 0 1 1 30 90 48 84 0 1 1 0 0 0.5 2
echo texture motifs   3 marimba motifex2c ndfmot2.txt 12 0.25 0 0 1 1 30 90 48 84 0 1 1 0 0 0.5 2
texture motifs   3 marimba motifex2c ndfmot2.txt 12 0.25 0 0 1 1 30 90 48 84 0 1 1 0 0 0.5 2
echo 

echo 

echo EXAMPLE 3a/b/c - two inputs \(marimba \& horn\) and two motifs;  the \'b\' 
echo	version has a 1/2 sec overlap, with no tempo variation.  The \'c\' 
echo	version uses Mode 1 which opens up different octaves.
echo ndfmot3.txt
echo 59 60
echo \#9				\(Harmonic Field/Set\)
echo 0.0 1 60 0 0
echo 0.0 1 61 0 0
echo 0.0 1 63 0 0
echo 0.0 1 64 0 0
echo 0.0 1 66 0 0
echo 0.0 1 67 0 0
echo 0.0 1 68 0 0
echo 0.0 1 70 0 0
echo 0.0 1 72 0 0
echo \#10				\(motif 1\)
echo 0.0 1 60 70 0.3
echo 0.1 1 61 50 0.3
echo 0.2 1 66 50 0.3
echo 0.3 1 67 50 0.3
echo 0.4 1 66 50 0.3
echo 0.5 1 67 70 0.3
echo 0.6 1 70 50 0.3
echo 0.7 1 66 50 0.3
echo 0.8 1 72 80 0.3
echo 0.9 1 66 60 0.3
echo \#3				\(motif 2\)
echo 0.0  1 60 40 1.5 
echo 0.34 1 67 45 1.5 
echo 0.67 1 72 50 1.5 
echo 

echo texture motifs 3 marimba horn motifex3a ndfmot3.txt 12 1.0 0 0 1 2 30 90 48 84 0 1 1 0 0 0.5 2
texture motifs 3 marimba horn motifex3a ndfmot3.txt 12 1.0 0 0 1 2 30 90 48 84 0 1 1 0 0 0.5 2
echo texture motifs 3 marimba horn motifex3b ndfmot3.txt 12 0.5 0 0 1 2 30 90 48 84 0 1 1 0 0 1 1
texture motifs 3 marimba horn motifex3b ndfmot3.txt 12 0.5 0 0 1 2 30 90 48 84 0 1 1 0 0 1 1
echo texture motifs 1 marimba horn motifex3c ndfmot3.txt 12 0.5 0 0 1 2 30 90 48 84 0 1 1 0 0 1 1
texture motifs 1 marimba horn motifex3c ndfmot3.txt 12 0.5 0 0 1 2 30 90 48 84 0 1 1 0 0 1 1
echo 

echo EXAMPLE 4 - uses Mode 4 to illustrate how the start pitches of the 
echo	motifs can be controlled by timing information in the Harmonic 
echo	Field/Set.  The tempo is increased \(0.75\) and a little overlap 
echo 	put in \(skiptime=0.5\) to allow more entries within the times.
	put in \(skiptime=0.5\) to allow more entries within the times.
echo ndfmot4.txt
echo 59 60
echo \#9				\(Harmonic Field/Set, with changing times\)
echo 0.0 1 60 0 0
echo 2.0 1 61 0 0
echo 2.0 1 63 0 0
echo 4.0 1 64 0 0
echo 4.0 1 66 0 0
echo 4.0 1 67 0 0
echo 6.0 1 68 0 0
echo 6.0 1 70 0 0
echo 6.0 1 72 0 0
echo \#10				\(motif 1\)
echo 0.0 1 60 70 0.3
echo 0.1 1 61 50 0.3
echo 0.2 1 66 50 0.3
echo 0.3 1 67 50 0.3
echo 0.4 1 66 50 0.3
echo 0.5 1 67 70 0.3
echo 0.6 1 70 50 0.3
echo 0.7 1 66 50 0.3
echo 0.8 1 72 80 0.3
echo 0.9 1 66 60 0.3
echo \#3				\(motif 2\)
echo 0.0  1 60 40 1.5
echo 0.34 1 67 45 1.5
echo 0.67 1 72 50 1.5
echo 

echo texture motifs 4 marimba horn motifex4 ndfmot4.txt 12 0.5 0 0  1 2 30 90 60 72 0 1 1 0 0  0.75 0.75
texture motifs 4 marimba horn motifex4 ndfmot4.txt 12 0.5 0 0  1 2 30 90 60 72 0 1 1 0 0  0.75 0.75
echo 




