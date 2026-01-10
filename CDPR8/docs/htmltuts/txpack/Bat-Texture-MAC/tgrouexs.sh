#!/bin/bash

echo - TGROUEXS.BAT - batch file for TEXTURE TGROUPED
echo - note data files: ndftgr1.txt
echo - breakpoint files: 

echo A Endrich - last updated 24 July 2000

echo 

echo set CDP_SOUND_EXT.aiff
set CDP_SOUND_EXT.aiff
echo 

echo ... minoutdur skiptime sndf sndl ming maxg mind maxd minp maxp 
echo phgrid gpspace gpsprange amprise contour 
echo gpsizelo gpsizehi gppaklo gppakhi gpranglo gpranghi
echo rem [-aatten -pposition -sspread -rseed -w -d -i]
echo 

echo 

echo EXAMPLE 1 - \'a\' reveals the role of the rhythmic template with 1-note 
echo	\'groups\'
echo		\'b\' now makes the groups clearer by having 3-note groups
echo		\'c\' opens things out with larger ranges
echo		\'d\' increases overlap by reducing skiptime below 1
echo ndftgr1.txt
echo 60
echo \#5		\(times template\)
echo 0.00 1 0 0 0
echo 0.25 1 0 0 0
echo 0.75 1 0 0 0
echo 1.00 1 0 0 0
echo 1.50 1 0 0 0
echo 

echo texture tgrouped 5 marimba tgrouex1a ndftgr1.txt 12 2.0  1 1  40 80 0.4 1.0 48 84 0 1 1 0 0  1 1 100 200 1 1
texture tgrouped 5 marimba tgrouex1a ndftgr1.txt 12 2.0  1 1  40 80 0.4 1.0 48 84 0 1 1 0 0  1 1 100 200 1 1
echo texture tgrouped 5 marimba tgrouex1b ndftgr1.txt 12 2.0  1 1  40 80 0.4 1.0 48 84 0 1 1 0 0  3 3 166 167 1 1
texture tgrouped 5 marimba tgrouex1b ndftgr1.txt 12 2.0  1 1  40 80 0.4 1.0 48 84 0 1 1 0 0  3 3 166 167 1 1
echo texture tgrouped 5 marimba tgrouex1c ndftgr1.txt 12 2.0  1 1  40 80 0.4 1.0 48 84 0 1 1 0 0 5 10 50 100 3 10
texture tgrouped 5 marimba tgrouex1c ndftgr1.txt 12 2.0  1 1  40 80 0.4 1.0 48 84 0 1 1 0 0 5 10 50 100 3 10
echo texture tgrouped 5 marimba tgrouex1d ndftgr1.txt 12 0.5  1 1  40 80 0.4 1.0 48 84 0 1 1 0 0  5 10 50 100 3 10
texture tgrouped 5 marimba tgrouex1d ndftgr1.txt 12 0.5  1 1  40 80 0.4 1.0 48 84 0 1 1 0 0  5 10 50 100 3 10
echo 

echo EXAMPLE 2 - a more supple texture by using parameter ranges;  pitches 
echo are restricted to harmonic field
are restricted to harmonic field
echo ndftgr2.txt
echo 60
echo \#4		\(times template\)
echo 0.00 1 0 0 0
echo 0.50 1 0 0 0
echo 3.00 1 0 0 0
echo 4.50 1 0 0 0
echo \#7		\(Harmonic Field/Set\)
echo 0.0  1 48 0 0
echo 0.0  1 53 0 0
echo 0.0  1 58 0 0
echo 0.0  1 63 0 0
echo 0.0  1 68 0 0
echo 0.0  1 73 0 0
echo 0.0  1 78 0 0
echo 

echo texture tgrouped 3 marimba tgrouex2 ndftgr2.txt 21 0.5 1 1 40 70 0.25 0.75  48 84 0 1 1 0 0 7 28 75 150 1 7
texture tgrouped 3 marimba tgrouex2 ndftgr2.txt 21 0.5 1 1 40 70 0.25 0.75  48 84 0 1 1 0 0 7 28 75 150 1 7
echo 



