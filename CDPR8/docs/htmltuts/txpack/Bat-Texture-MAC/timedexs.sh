#!/bin/bash

echo - TIMEDEXS.BAT - batch file for TEXTURE TIMED
echo - note data files: ndftim1.txt, ndftim2.txt, ndftim3.txt
echo - breakpoint files:  

echo A Endrich - last updated 24 July 2000

echo 

echo set CDP_SOUND_EXT.aiff
set CDP_SOUND_EXT.aiff
echo 

echo rem  notedata outdur skiptime  
echo   snd1st sndlast  mingain maxgain 
echo    mindur maxdur minpch maxpch
echo      -aatten -ppos -ssprd -rseed -w
echo 

echo EXAMPLE 1 - pitches from a wide pitch range are played on a 
echo	rhythmic template which repeats after 1 sec silence;  event 
echo durations are taken from a duration range
echo ndftim1.txt
echo 60
echo \#5		\(times template\)
echo 0.00 1 0 0 0
echo 0.25 1 0 0 0
echo 0.75 1 0 0 0
echo 1.00 1 0 0 0
echo 1.50 1 0 0 0
echo 

echo texture timed 5 marimba timedex1 ndftim1.txt 12 1.0  1 1 24 84 0.2 1.0  48 84
texture timed 5 marimba timedex1 ndftim1.txt 12 1.0  1 1 24 84 0.2 1.0  48 84
echo 

echo EXAMPLE 2 - pitches for the rhythmic template are selected from and 
echo restricted to a user-defined pitch field
restricted to a user-defined pitch field
echo ndftim2.txt
echo 60
echo \#5			\(times template\)
echo 0.00 1 0 0 0
echo 0.25 1 0 0 0
echo 0.75 1 0 0 0
echo 1.00 1 0 0 0
echo 1.50 1 0 0 0
echo \#6		\(Harmonic Field/Set\)
echo 0.0 1 60 0 0
echo 0.0 1 62 0 0
echo 0.0 1 63 0 0
echo 0.0 1 72 0 0
echo 0.0 1 74 0 0
echo 0.0 1 76 0 0
echo 

echo texture timed 3 marimba timedex2 ndftim2.txt 12 1.0  1 1 24 84 0.2 1.0  48 84
texture timed 3 marimba timedex2 ndftim2.txt 12 1.0  1 1 24 84 0.2 1.0  48 84
echo 

echo EXAMPLE 3 - quick note gesture repeats, drawing pitches from a very 
echo	small harmonic grid;  note events are longer and care is taken 
echo	to have it repeat \'on the beat\' \(skiptime is 0.1, the duration 
echo	of the last event so that it will come out even at 2 sec.\)
echo 60
echo \#17		\(times template\)
echo 0.00 1 0 0 0
echo 0.05 1 0 0 0
echo 0.10 1 0 0 0
echo 0.15 1 0 0 0
echo 0.20 1 0 0 0
echo 0.25 1 0 0 0
echo 0.30 1 0 0 0
echo 0.35 1 0 0 0
echo 0.40 1 0 0 0
echo 0.45 1 0 0 0
echo 0.50 1 0 0 0
echo 1.00 1 0 0 0
echo 1.50 1 0 0 0
echo 1.60 1 0 0 0
echo 1.70 1 0 0 0
echo 1.80 1 0 0 0
echo 1.90 1 0 0 0
echo \#5		\(Harmonic Field/Set\)
echo 0.0 1 48 0 0
echo 0.0 1 50 0 0
echo 0.0 1 53 0 0
echo 0.0 1 55 0 0
echo 0.0 1 58 0 0
echo 

echo texture timed 3 marimba timedex3a ndftim3.txt 12 0.1  1 1 40 80 0.4 1.0  48 84
texture timed 3 marimba timedex3a ndftim3.txt 12 0.1  1 1 40 80 0.4 1.0  48 84
echo texture timed 1 marimba timedex3b ndftim3.txt 12 0.1  1 1 40 80 0.4 1.0  48 84
texture timed 1 marimba timedex3b ndftim3.txt 12 0.1  1 1 40 80 0.4 1.0  48 84
echo 



