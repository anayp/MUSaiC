prompt $G

rem rmrepeat.bat - batch file for Sound-Builder Template 5 
rem  (as in CDP File Formats: filestxt.htm, but path and 
rem    file names have been changed
rem This batch file chains 3 functions to produce a churning 
rem   and deeply sonorous result
rem See rmrepdel.bat for deletions between uses


echo on

rem COPY TO GENERIC NAME
copysfx asrcmix.wav e.wav

rem MODIFY RADICAL:  Mode 5 is Ring Modulation, Mod Freq is 1000
rem (1000 is higher than the max shown in SoundShaper, but 
rem   it is accepted by the program)
modify radical 5  e  erm  1000
rem (the speech part of the source was most affected)

rem DISTORT REPEAT: Parameters: Multiplier and Cyclecount
distort repeat  erm  ermrpt  2  -c2
rem (this doubles the lengths and roughs it up a lot!)

rem MODIFY SPEED: lowered by 11 semitones
modify speed 2  ermrpt  ermrptd11  -11 
rem (nearly doubles the length again, deepening and smoothing)

echo off

prompt $P$G
