#!/bin/bash

echo  ORNATEXS.BAT - examples for TEXTURE ORNATE
echo note data files: ndforn1.txt, ndforn2.txt, ndforn3.txt, ndforn4.txt
echo breakpoint files: none

echo  A Endrich - last updated: 24 July 2000

echo 

echo set CDP_SOUND_EXT.aiff
set CDP_SOUND_EXT.aiff
echo 

echo	 ... minoutdur \(12\) skiptime \(2\) 
echo	sndf \(1\) sndl \(1\) ming \(30\) maxg \(90\) mind \(1.0\) maxd \(1.0\) 
echo	phgrid \(0\) gpspace \(1\) gpsprange \(1\) amprise \(0\) contour \(0\) 
echo	multlo \(1\) multhi \(1\)
echo 

echo Example 1 - Mode 5: a \'turn\' on 4 different notes
echo ndforn1.txt
echo 60
echo \#4				\(nodal substructure\)
echo 0.0 1 60 0 0
echo 2.0 1 67 0 0
echo 4.0 1 65 0 0
echo 6.0 1 62 0 0
echo \#5				\(ornament\)
echo 0.0 1 60 90 0.3
echo 0.2 1 62 80 0.3
echo 0.4 1 60 70 0.3
echo 0.6 1 58 60 0.3
echo 0.8 1 60 70 0.3
echo 

echo texture postornate 5 marimba ornatex1 ndforn1.txt 12 2 1 1 30 90 1 1 0 1 1 0 0 1 1
texture postornate 5 marimba ornatex1 ndforn1.txt 12 2 1 1 30 90 1 1 0 1 1 0 0 1 1
echo 

echo 

echo Example 2 - a single ornament is attached to two different nodes, 
echo   and two different input sounds are used.
echo ndforn2.txt
echo 59 60
echo \#2				\(nodal substructure\)
echo 0.0 1 60 0 0
echo 2.0 1 67 0 0
echo \#8				\(Harmonic Field/Set\)
echo 0.0 1 60 0 0
echo 0.0 1 62 0 0
echo 0.0 1 63 0 0
echo 0.0 1 65 0 0
echo 0.0 1 67 0 0
echo 0.0 1 69 0 0
echo 0.0 1 70 0 0
echo 0.0 1 72 0 0
echo \#8				\(ornament\)
echo 0.0    2 60 30 0.5
echo 0.25   2 62 30 0.5
echo 0.5    2 63 30 0.5
echo 0.8333 2 62 30 0.5
echo 1.0    1 63 30 0.5
echo 1.25   1 65 30 0.5
echo 1.5    1 63 30 0.5
echo 1.75   1 62 30 0.5
echo 

echo texture postornate 3 marimba horn ornatex2 ndforn2.txt 12 2 1 2 30 90 1 1 0 1 1 0 0 1 1
texture postornate 3 marimba horn ornatex2 ndforn2.txt 12 2 1 2 30 90 1 1 0 1 1 0 0 1 1
echo 

echo 

echo Example 3 - several different ornaments are selected at random and 
echo   attached to 5 ascending nodes
echo ndforn3.txt
echo 60
echo \#5				\(nodal substructure\)
echo 0.0  1 60 0 0
echo 3.0  1 62 0 0
echo 6.0  1 63 0 0
echo 9.0  1 65 0 0
echo 12.0 1 67 0 0
echo \#17				\(Harmonic Field/Set\)
echo 0.0 1 60 0 0
echo 0.0 1 62 0 0
echo 0.0 1 63 0 0
echo 0.0 1 64 0 0
echo 0.0 1 65 0 0
echo 0.0 1 66 0 0
echo 0.0 1 67 0 0
echo 0.0 1 68 0 0
echo 0.0 1 69 0 0
echo 0.0 1 70 0 0
echo 0.0 1 71 0 0
echo 0.0 1 72 0 0
echo 0.0 1 73 0 0
echo 0.0 1 74 0 0
echo 0.0 1 75 0 0
echo 0.0 1 76 0 0
echo 0.0 1 77 0 0
echo \#8				\(ornament 1\)
echo 0.0    1 60 60 0.5
echo 0.25   1 62 55 0.5
echo 0.5    1 63 65 0.5
echo 0.8333 1 62 55 0.5
echo 1.0    1 63 70 0.5
echo 1.25   1 65 65 0.5
echo 1.5    1 63 60 0.5
echo 1.75   1 62 55 0.5
echo \#8				\(ornament 2\)
echo 0.0    1 60 70 0.5
echo 0.2    1 63 72 0.5
echo 0.4    1 62 74 0.5
echo 0.6    1 65 76 0.5
echo 0.8    1 63 78 0.5
echo 1.0    1 66 90 0.5
echo 1.5    1 67 85 0.5
echo 1.75   1 66 85 0.5
echo \#6				\(ornament 3\)
echo 0.0    1 60 60 0.5
echo 0.34   1 63 50 0.5
echo 0.67   1 67 50 0.5
echo 1.00   1 62 60 0.5
echo 1.25   1 62 45 0.5
echo 1.50   1 66 50 0.5
echo \#6				\(ornament 4\)
echo 0.0    1 60 50 0.5
echo 0.25   1 67 60 0.5
echo 0.75   1 60 40 0.5
echo 1.00   1 65 70 0.5
echo 1.50   1 65 70 0.5
echo 1.75   1 62 65 0.5
echo \#14				\(ornament 5\)
echo 0.0   1 60 40 0.5
echo 0.125 1 62 45 0.5
echo 0.25  1 63 50 0.5
echo 0.375 1 65 55 0.5
echo 0.5   1 67 60 0.5
echo 0.625 1 65 55 0.5
echo 0.75  1 63 50 0.5
echo 0.875 1 62 45 0.5
echo 1.0   1 63 70 0.5
echo 1.17  1 65 65 0.5
echo 1.33  1 67 70 0.5
echo 1.5   1 65 65 0.5
echo 1.66  1 63 70 0.5
echo 1.83  1 62 70 0.5
echo 

echo texture postornate 3 marimba ornatex3 ndforn3.txt 21 4 1 1 30 90 1 1 0 1 1 0 0 0.5 1.2
texture postornate 3 marimba ornatex3 ndforn3.txt 21 4 1 1 30 90 1 1 0 1 1 0 0 0.5 1.2
echo 

echo 

echo 

echo Example 4 - rising and falling scale with varied degrees of overlap and 
echo	tempo acceleration 
echo ndforn4.txt
echo 60
echo \#1				\(nodal substructure\)
echo 0.0  1 60 0 0
echo \#8				\(Harmonic Field/Set\)
echo 0.0  1 60 0 0
echo 0.0  1 62 0 0
echo 0.0  1 63 0 0
echo 0.0  1 65 0 0
echo 0.0  1 67 0 0
echo 0.0  1 69 0 0
echo 0.0  1 70 0 0
echo 0.0  1 72 0 0
echo \#16				\(ornament 1\)
echo 0.0  1 60 50 0.3
echo 0.25 1 62 55 0.3
echo 0.5  1 63 60 0.3
echo 0.75 1 65 65 0.3
echo 1.0  1 67 70 0.3
echo 1.25 1 69 75 0.3
echo 1.5  1 70 80 0.3
echo 1.75 1 72 85 0.3
echo 2.0  1 72 85 0.3
echo 2.25 1 70 85 0.3
echo 2.5  1 69 85 0.3
echo 2.75 1 67 85 0.3
echo 3.0  1 65 85 0.3
echo 3.25 1 63 85 0.3
echo 3.5  1 62 85 0.3
echo 3.75 1 60 85 0.5
echo 

echo texture postornate 3 marimba ornatex4 ndforn4.txt 12 0.5 1 1 30 90 1 1 0 1 1 0 0 1 1 -a0.9
texture postornate 3 marimba ornatex4 ndforn4.txt 12 0.5 1 1 30 90 1 1 0 1 1 0 0 1 1 -a0.9
echo 



