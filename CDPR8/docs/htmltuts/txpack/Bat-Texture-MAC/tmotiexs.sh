#!/bin/bash

echo tmotiexs.bat - batch file for TMOTIFS/TMOTIFSIN
echo input soundfile: I favour the marimba.aiff sound.
echo note data files: ndftmo1.txt, ndftmo2.txt
echo breakpoint files: none

echo A Endrich - last updated 13 November 2000

echo  notedata outdur skiptime 
echo   snd1st sndlast  mingain maxgain minpich maxpich
echo    phgrid gpspace gpsprange amprise contour multlo multhi 
echo	 -aatten -ppos -ssprd -rseed -w -d -i


echo 

echo set CDP_SOUND_EXT.aiff
set CDP_SOUND_EXT.aiff
echo 

echo Example 1 - motif repeats at decreasing time intervals.  Skiptime 
echo	creates pauses and keeps the repetitions \'on the beat\'
echo ndftmo1.txt
echo 60
echo \#5			\(times template\)
echo 0.0 1 0 0 0
echo 3.0 1 0 0 0
echo 5.0 1 0 0 0
echo 6.0 1 0 0 0
echo 6.5 1 0 0 0
echo \#6			\(motif\)
echo 0.000 1 63 70 0.4
echo 0.167 1 62 65 0.3
echo 0.334 1 60 60 0.3
echo 0.500 1 62 65 0.4
echo 0.667 1 60 60 0.3
echo 0.834 1 59 55 0.3
echo 

echo texture tmotifs 5 marimba tmotiex1 ndftmo1.txt 21 3.5 1 1 40 80 48 84 0 1 1 0 0 1 1
texture tmotifs 5 marimba tmotiex1 ndftmo1.txt 21 3.5 1 1 40 80 48 84 0 1 1 0 0 1 1
echo 

echo Example 2 - rising arpeggio with harmonies resulting from overlaps
echo
echo ndftmo2.txt
echo 60
echo \#5			\(times template\)
echo 0.0 1 0 0 0
echo 0.5 1 0 0 0
echo 1.0 1 0 0 0
echo 1.5 1 0 0 0
echo 2.0 1 0 0 0
echo \#9			\(Harmonic Field/Set\)
echo 0.0 1 52 60 0
echo 0.0 1 55 60 0
echo 0.0 1 58 60 0
echo 0.0 1 61 60 0
echo 0.0 1 63 60 0
echo 0.0 1 66 60 0
echo 0.0 1 68 60 0
echo 0.0 1 72 60 0
echo 0.0 1 75 60 0
echo \#18			\(motif\)
echo 0.000 1 52 70 0.4
echo 0.167 1 55 65 0.3
echo 0.334 1 58 60 0.3
echo 0.500 1 55 65 0.4
echo 0.667 1 58 60 0.3
echo 0.834 1 61 55 0.3
echo 1.000 1 58 70 0.4
echo 1.167 1 61 65 0.3
echo 1.334 1 63 60 0.3
echo 1.500 1 61 65 0.4
echo 1.667 1 63 60 0.3
echo 1.834 1 66 55 0.3
echo 2.000 1 63 70 0.4
echo 2.167 1 66 65 0.3
echo 2.334 1 68 60 0.3
echo 2.500 1 66 65 0.4
echo 2.667 1 68 60 0.3
echo 2.834 1 72 55 0.3
echo 

echo texture tmotifs 3 marimba tmotiex2a ndftmo2.txt 21 0.50 1 1 40 80 48 96 0 1 1 0 0 1 1 -a0.8
texture tmotifs 3 marimba tmotiex2a ndftmo2.txt 21 0.50 1 1 40 80 48 96 0 1 1 0 0 1 1 -a0.8
echo texture tmotifs 3 marimba tmotiex2b ndftmo2.txt 21 0.75 1 1 40 80 48 96 0 1 1 0 0 1 1 -a0.8
texture tmotifs 3 marimba tmotiex2b ndftmo2.txt 21 0.75 1 1 40 80 48 96 0 1 1 0 0 1 1 -a0.8
echo 




