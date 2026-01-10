#!/bin/bash

echo rmrepeat.bat - batch file for Sound-Builder Template 5 
echo  \(as in CDP File Formats: filestxt.htm, but path and 
echo    file names have been changed
echo This batch file chains 3 functions to produce a churning 
echo   and deeply sonorous result
echo See rmrepdel.bat for deletions between uses


echo 

echo COPY TO GENERIC NAME
echo copysfx asrcmix.aiff e.aiff
copysfx asrcmix.aiff e.aiff
echo 

echo MODIFY RADICAL:  Mode 5 is Ring Modulation, Mod Freq is 1000
echo \(1000 is higher than the max shown in SoundShaper, but 
echo   it is accepted by the program\)
echo modify radical 5  e  erm  1000
modify radical 5  e  erm  1000
echo \(the speech part of the source was most affected\)
echo 

echo DISTORT REPEAT: Parameters: Multiplier and Cyclecount
echo distort repeat  erm  ermrpt  2  -c2
distort repeat  erm  ermrpt  2  -c2
echo \(this doubles the lengths and roughs it up a lot!\)
echo 

echo MODIFY SPEED: lowered by 11 semitones
echo modify speed 2  ermrpt  ermrptd11  -11 
modify speed 2  ermrpt  ermrptd11  -11 
echo \(nearly doubles the length again, deepening and smoothing\)
echo 


