rem - TIMEDEXS.BAT - batch file for TEXTURE TIMED
rem - note data files: ndftim1.txt, ndftim2.txt, ndftim3.txt
rem - breakpoint files:  

echo on
rem rem  notedata outdur skiptime  
rem   snd1st sndlast  mingain maxgain 
rem    mindur maxdur minpch maxpch
rem      -aatten -ppos -ssprd -rseed -w

rem EXAMPLE 1 - pitches from a wide pitch range are played on a 
rem	rhythmic template which repeats after 1 sec silence;  event 
rem durations are taken from a duration range
rem ndftim1.txt
rem 60
rem #5
rem 0.00 1 0 0 0
rem 0.25 1 0 0 0
rem 0.75 1 0 0 0
rem 1.00 1 0 0 0
rem 1.50 1 0 0 0

texture timed 5 marimba timedex1 ndftim1.txt 12 1.0  1 1 24 84 0.2 1.0  48 84

rem EXAMPLE 2 - pitches for the rhythmic template are selected from and 
restricted to a user-defined pitch field
rem ndftim2.txt
rem 60
rem #5
rem 0.00 1 0 0 0
rem 0.25 1 0 0 0
rem 0.75 1 0 0 0
rem 1.00 1 0 0 0
rem 1.50 1 0 0 0
rem #6
rem 0.0 1 60 0 0
rem 0.0 1 62 0 0
rem 0.0 1 63 0 0
rem 0.0 1 72 0 0
rem 0.0 1 74 0 0
rem 0.0 1 76 0 0

texture timed 3 marimba timedex2 ndftim2.txt 12 1.0  1 1 24 84 0.2 1.0  48 84

rem EXAMPLE 3 - quick note gesture repeats, drawing pitches from a very 
rem	small harmonic grid;  note events are longer and care is taken 
rem	to have it repeat 'on the beat' (skiptime is 0.1, the duration 
rem	of the last event so that it will come out even at 2 sec.)
rem 60
rem #17
rem 0.00 1 0 0 0
rem 0.05 1 0 0 0
rem 0.10 1 0 0 0
rem 0.15 1 0 0 0
rem 0.20 1 0 0 0
rem 0.25 1 0 0 0
rem 0.30 1 0 0 0
rem 0.35 1 0 0 0
rem 0.40 1 0 0 0
rem 0.45 1 0 0 0
rem 0.50 1 0 0 0
rem 1.00 1 0 0 0
rem 1.50 1 0 0 0
rem 1.60 1 0 0 0
rem 1.70 1 0 0 0
rem 1.80 1 0 0 0
rem 1.90 1 0 0 0
rem #5
rem 0.0 1 48 0 0
rem 0.0 1 50 0 0
rem 0.0 1 53 0 0
rem 0.0 1 55 0 0
rem 0.0 1 58 0 0

texture timed 3 marimba timedex3a ndftim3.txt 12 0.1  1 1 40 80 0.4 1.0  48 84
texture timed 1 marimba timedex3b ndftim3.txt 12 0.1  1 1 40 80 0.4 1.0  48 84

echo off
