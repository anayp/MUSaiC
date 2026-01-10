prompt $G

rem tmotiexs.bat - batch file for TMOTIFS/TMOTIFSIN
rem input soundfile: I favour the marimba.wav sound.
rem note data files: ndftmo1.txt, ndftmo2.txt
rem breakpoint files: none

rem A Endrich - last updated 13 November 2000

rem  notedata outdur skiptime 
rem   snd1st sndlast  mingain maxgain minpich maxpich
rem    phgrid gpspace gpsprange amprise contour multlo multhi 
rem	 -aatten -ppos -ssprd -rseed -w -d -i


echo on

set CDP_SOUND_EXT=wav

rem Example 1 - motif repeats at decreasing time intervals.  Skiptime 
rem	creates pauses and keeps the repetitions 'on the beat'
rem ndftmo1.txt
rem 60
rem #5				(times template)
rem 0.0 1 0 0 0
rem 3.0 1 0 0 0
rem 5.0 1 0 0 0
rem 6.0 1 0 0 0
rem 6.5 1 0 0 0
rem #6				(motif)
rem 0.000 1 63 70 0.4
rem 0.167 1 62 65 0.3
rem 0.334 1 60 60 0.3
rem 0.500 1 62 65 0.4
rem 0.667 1 60 60 0.3
rem 0.834 1 59 55 0.3

texture tmotifs 5 marimba tmotiex1 ndftmo1.txt 21 3.5 1 1 40 80 48 84 0 1 1 0 0 1 1

rem Example 2 - rising arpeggio with harmonies resulting from overlaps
rem
rem ndftmo2.txt
rem 60
rem #5				(times template)
rem 0.0 1 0 0 0
rem 0.5 1 0 0 0
rem 1.0 1 0 0 0
rem 1.5 1 0 0 0
rem 2.0 1 0 0 0
rem #9				(Harmonic Field/Set)
rem 0.0 1 52 60 0
rem 0.0 1 55 60 0
rem 0.0 1 58 60 0
rem 0.0 1 61 60 0
rem 0.0 1 63 60 0
rem 0.0 1 66 60 0
rem 0.0 1 68 60 0
rem 0.0 1 72 60 0
rem 0.0 1 75 60 0
rem #18				(motif)
rem 0.000 1 52 70 0.4
rem 0.167 1 55 65 0.3
rem 0.334 1 58 60 0.3
rem 0.500 1 55 65 0.4
rem 0.667 1 58 60 0.3
rem 0.834 1 61 55 0.3
rem 1.000 1 58 70 0.4
rem 1.167 1 61 65 0.3
rem 1.334 1 63 60 0.3
rem 1.500 1 61 65 0.4
rem 1.667 1 63 60 0.3
rem 1.834 1 66 55 0.3
rem 2.000 1 63 70 0.4
rem 2.167 1 66 65 0.3
rem 2.334 1 68 60 0.3
rem 2.500 1 66 65 0.4
rem 2.667 1 68 60 0.3
rem 2.834 1 72 55 0.3

texture tmotifs 3 marimba tmotiex2a ndftmo2.txt 21 0.50 1 1 40 80 48 96 0 1 1 0 0 1 1 -a0.8
texture tmotifs 3 marimba tmotiex2b ndftmo2.txt 21 0.75 1 1 40 80 48 96 0 1 1 0 0 1 1 -a0.8

echo off

prompt $P$G


