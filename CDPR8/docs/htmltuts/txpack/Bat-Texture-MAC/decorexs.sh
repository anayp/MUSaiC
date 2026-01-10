#!/bin/bash

echo DECOREXS.BAT - examples for TEXTURE DECORATED
echo note data files:  ndfdec1.txt, ndfdec2a/2b/2c.txt, ndfdec3.txt 
echo breakpoint files: dm5gprhi.brk, dx3gprhi.brk
echo			0.0	1    0	8
echo			2.0	8    5	10
echo			4.0	1    10 15	
echo			6.0	6    15 12
echo			8.0	1    20 11
echo			10.0	10
echo			12.0	1
echo			14.0	7
echo			16.0	1
echo			18.0	9
echo			20.0	1

echo  A Endrich - last updated: 24 July 2000

echo 

echo set CDP_SOUND_EXT.aiff
set CDP_SOUND_EXT.aiff
echo 

echo	 ... minoutdur \(20\) skiptime \(2.0\) 
echo	sndf \(1\) sndl \(1\) ming \(36\) maxg \(64\) mind \(1.0\) maxd \(1.0\) 
echo	phgrid \(0\) gpspace \(1\) gpsprange \(1\) amprise \(0\) contour \(0\) 
echo	gpsizelo \(5\) gpsizehi \(5\) gppaklo \(60\) gppakhi \(60\) 
echo	gpranglo \(1\) gpranghi \(1\) centring \(0\)
echo 

echo Example 1a - 4-node substructure with repeating notes decoration
echo ndfdec1.txt
echo 60
echo \#4			\(\'line\' nodal substructure\)
echo 0.0 1 60 0 0
echo 2.0 1 67 0 0
echo 4.0 1 63 0 0
echo 6.0 1 62 0 0
echo 

echo texture decorated 5 marimba decorex1a ndfdec1.txt 20 2.0 1 1 36 64 1.0 1.0 0 1 1 0 0 5 5 60 60 1 1 0
texture decorated 5 marimba decorex1a ndfdec1.txt 20 2.0 1 1 36 64 1.0 1.0 0 1 1 0 0 5 5 60 60 1 1 0
echo 

echo Example 1b - decorations alternate between 1 and several notes and 
echo   are timed to occur on the nodes \(POSTDECOR\).
echo 

echo texture postdecor 5 marimba decorex1b ndfdec1.txt 20 2.0 1 1 36 64 1.0 1.0 0 1 1 0 0 5 5 60 60 1 dm5gprhi.brk 0
texture postdecor 5 marimba decorex1b ndfdec1.txt 20 2.0 1 1 36 64 1.0 1.0 0 1 1 0 0 5 5 60 60 1 dm5gprhi.brk 0
echo 

echo 

echo Example 2a - Mode 3 harmonic set:  all nodes decorated with the same chord
echo ndfdec2a.txt
echo 60
echo \#4			\(\'line\' nodal substructure\)
echo 0.0 1 60 0 0
echo 2.0 1 67 0 0
echo 4.0 1 63 0 0
echo 6.0 1 60 0 0
echo \#3			\(Harmonic Field/Set\)
echo 0.0 1 60 0 0
echo 0.0 1 64 0 0
echo 0.0 1 67 0 0
echo  
 
echo texture postdecor 3 marimba decorex2a ndfdec2a.txt 20 2.0 1 1 36 64 1.0 1.0 0 1 1 0 0 5 9 60 60 3 3 1
texture postdecor 3 marimba decorex2a ndfdec2a.txt 20 2.0 1 1 36 64 1.0 1.0 0 1 1 0 0 5 9 60 60 3 3 1
echo 

echo Example 2b - triads transposed, built on \(above\) each node
echo ndfdec2b.txt
echo 60
echo \#4			\(\'line\' nodal substructure\)
echo 0.0 1 60 0 0
echo 2.0 1 67 0 0
echo 4.0 1 63 0 0
echo 6.0 1 60 0 0
echo \#13			\(Harmonic Field/Set\)
echo 0.0 1 60 0 0
echo 0.0 1 64 0 0
echo 0.0 1 67 0 0
echo 0.0 1 67 0 0
echo 0.0 1 71 0 0
echo 0.0 1 72 0 0
echo 0.0 1 63 0 0
echo 0.0 1 67 0 0
echo 0.0 1 70 0 0
echo 0.0 1 60 0 0
echo 0.0 1 61 0 0
echo 0.0 1 66 0 0
echo 0.0 1 67 0 0
echo 

echo texture postdecor 3 marimba decorex2b ndfdec2b.txt 20 2.0 1 1 36 64 1.0 1.0 0 1 1 0 0 5 9 60 60 3 3 1
texture postdecor 3 marimba decorex2b ndfdec2b.txt 20 2.0 1 1 36 64 1.0 1.0 0 1 1 0 0 5 9 60 60 3 3 1
echo 

echo Example 2c - dyads selected from a decoration field all of whose notes 
echo   start at time 0
echo ndfdec2c.txt
echo 60
echo \#4			\(\'line\' nodal substructure\)
echo 0.0 1 55 0 0
echo 2.0 1 58 0 0
echo 4.0 1 62 0 0
echo 6.0 1 65 0 0
echo \#8			\(Harmonic Field/Set\)
echo 0.0 1 55 0 0
echo 0.0 1 58 0 0
echo 0.0 1 62 0 0
echo 0.0 1 65 0 0
echo 0.0 1 67 0 0
echo 0.0 1 70 0 0
echo 0.0 1 74 0 0
echo 0.0 1 77 0 0
echo 

echo texture postdecor 3 marimba decorex2c ndfdec2c.txt 20 2.0 1 1 36 64 1.0 1.0 0 1 1 0 0 5 5 60 60 2 2 1
texture postdecor 3 marimba decorex2c ndfdec2c.txt 20 2.0 1 1 36 64 1.0 1.0 0 1 1 0 0 5 5 60 60 2 2 1
echo 

echo Example 3 - varied bursts of notes separated by silence
echo ndfdec3.txt
echo 60
echo \#5			\(\'line\' nodal substructure\)
echo 0.0  1 60 0 0
echo 5.0  1 67 0 0
echo 10.0 1 66 0 0
echo 15.0 1 62 0 0
echo 20.0 1 64 0 0
echo \#15			\(Harmonic Field/Set\)
echo 0.0 1 49 0 0
echo 0.0 1 52 0 0
echo 0.0 1 54 0 0
echo 0.0 1 55 0 0
echo 0.0 1 58 0 0
echo 0.0 1 60 0 0
echo 0.0 1 61 0 0
echo 0.0 1 64 0 0
echo 0.0 1 66 0 0
echo 0.0 1 67 0 0
echo 0.0 1 70 0 0
echo 0.0 1 72 0 0
echo 0.0 1 73 0 0
echo 0.0 1 76 0 0
echo 0.0 1 78 0 0
echo 

echo texture postdecor 3 marimba decorex3 ndfdec3.txt 20 1 1 1 36 64 1.0 1.0 0 1 1 0 0 10 25 40 125 2 dx3gprhi.brk 0
texture postdecor 3 marimba decorex3 ndfdec3.txt 20 1 1 1 36 64 1.0 1.0 0 1 1 0 0 10 25 40 125 2 dx3gprhi.brk 0
echo 



