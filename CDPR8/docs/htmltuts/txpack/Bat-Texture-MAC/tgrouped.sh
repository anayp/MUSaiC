#!/bin/bash

echo TGROUPED.sh - batch file to study TEXTURE TGROUPED
echo  notedata outdur skiptime 
echo   snd1st sndlast  mingain maxgain mindur maxdur minpch maxpch
echo    phgrid grpspace gpsprange amprise contour 
echo     gpsizelo gpsizehi gppaklo gppakhi gppranglo gppranghi
echo      [-aatten -ppos -ssprd -rseed -w]

texture tgrouped 3 marimba tgrouped ndftgr2.txt 21 0.5 1 1 40 70 0.25 0.75  48 84 0 1 1 0 0 7 28 75 150 1 7

