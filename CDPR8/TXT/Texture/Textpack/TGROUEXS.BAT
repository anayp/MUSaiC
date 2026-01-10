rem - TGROUEXS.BAT - batch file for TEXTURE TGROUPED
rem - note data files: ndftgr1.txt
rem - breakpoint files: 

echo on
rem ... minoutdur skiptime sndf sndl ming maxg mind maxd minp maxp 
rem phgrid gpspace gpsprange amprise contour 
rem gpsizelo gpsizehi gppaklo gppakhi gpranglo gpranghi
rem rem [-aatten -pposition -sspread -rseed -w -d -i]


rem EXAMPLE 1 - 'a' reveals the role of the rhythmic template with 1-note 
rem	'groups'
rem		'b' now makes the groups clearer by having 3-note groups
rem		'c' opens things out with larger ranges
rem		'd' increases overlap by reducing skiptime below 1
rem ndftgr1.txt
rem 60
rem #5
rem 0.00 1 0 0 0
rem 0.25 1 0 0 0
rem 0.75 1 0 0 0
rem 1.00 1 0 0 0
rem 1.50 1 0 0 0

texture tgrouped 5 marimba tgrouex1a ndftgr1.txt 12 2.0  1 1  40 80 0.4 1.0 48 84 0 1 1 0 0  1 1 100 200 1 1
texture tgrouped 5 marimba tgrouex1b ndftgr1.txt 12 2.0  1 1  40 80 0.4 1.0 48 84 0 1 1 0 0  3 3 166 167 1 1
texture tgrouped 5 marimba tgrouex1c ndftgr1.txt 12 2.0  1 1  40 80 0.4 1.0 48 84 0 1 1 0 0 5 10 50 100 3 10
texture tgrouped 5 marimba tgrouex1d ndftgr1.txt 12 0.5  1 1  40 80 0.4 1.0 48 84 0 1 1 0 0  5 10 50 100 3 10

rem EXAMPLE 2 - a more supple texture by using parameter ranges;  pitches 
are restricted to harmonic field
rem ndftgr2.txt
rem 60
rem #4
rem 0.00 1 0 0 0
rem 0.50 1 0 0 0
rem 3.00 1 0 0 0
rem 4.50 1 0 0 0
rem #7
rem 0.0  1 48 0 0
rem 0.0  1 53 0 0
rem 0.0  1 58 0 0
rem 0.0  1 63 0 0
rem 0.0  1 68 0 0
rem 0.0  1 73 0 0
rem 0.0  1 78 0 0

texture tgrouped 3 marimba tgrouex2 ndftgr2.txt 21 0.5 1 1 40 70 0.25 0.75  48 84 0 1 1 0 0 7 28 75 150 1 7

echo off
