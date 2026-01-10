prompt $G

rem GROUPEXS.BAT - list of examples to illustrate TEXTURE GROUP
rem  RENAME FILE EXTENSION TO .bat TO RUN (make sure you've created all 
rem	the required note data files, if not supplied with this batch file)
rem infile:  horn.wav as in Theocharidis' GrainMill tutorial
rem ndfs: ndfgrp1.txt
rem	60
rem	#4			(Harmonic Field/Set)
rem	0 1 62 0 0
rem	0 1 64 0 0
rem	0 1 65 0 0
rem	0 1 67 0 0

rem time-varying parameters:  grppack.brk
rem				0.0  2.0
rem			       12.0  0.5

rem A Endrich - last updated 24 July 2000

rem *****

echo on

set CDP_SOUND_EXT=wav

rem Ex 1. - Produces several separated groups of rapid-fire note events

rem minoutdur packing scatter tgrid 
rem sndf sndl ming maxg mind maxd minp maxp 
rem phgrid gpspace gpsprange amprise contour 
rem gpsizelo gpsizehi gppaklo gppakhi gpranglo gpranghi

texture grouped 3 horn groupex1 ndfgrp1.txt 12 2  0 0 1 1  30 64 0.25 1.2 36 84 0 1 1 0 0 10 20 25 50 4 4


rem *****
rem Ex 2. - Produces several groups of rapid-fire note events that get 
rem	closer together
rem grppack.brk: packing parameter: 0 2, 12 0.5

rem minoutdur packing scatter tgrid 
rem sndf sndl ming maxg mind maxd minp maxp 
rem phgrid gpspace gpsprange amprise contour 
rem gpsizelo gpsizehi gppaklo gppakhi gpranglo gpranghi

texture grouped 3 horn groupex2 ndfgrp1.txt 12 grppack.brk  0 0 1 1  30 64 0.25 1.2 36 84 0 1 1 0 0 10 20 25 50 4 4


rem *****
rem Ex 3. - Produces several groups with more internal regularity
rem	phgrid is invoked and gppakhi set to the same value as phgrid

rem minoutdur packing scatter tgrid 
rem sndf sndl ming maxg mind maxd minp maxp 
rem phgrid gpspace gpsprange amprise contour 
rem gpsizelo gpsizehi gppaklo gppakhi gpranglo gpranghi

texture grouped 3 horn groupex3 ndfgrp1.txt 12 2  0 0 1 1  30 64 0.25 1.2 36 84 200 1 1 0 0 10 20 25 200 4 4


rem *****
rem Ex 4. - Produces more note overlap simply by changing mindur to 0.75 
rem	-- all other parameters the same as in Ex. 3.

rem minoutdur packing scatter tgrid 
rem sndf sndl ming maxg mind maxd minp maxp 
rem phgrid gpspace gpsprange amprise contour 
rem gpsizelo gpsizehi gppaklo gppakhi gpranglo gpranghi

texture grouped 3 horn groupex4 ndfgrp1.txt 12 2  0 0 1 1  30 64 0.75 1.2 36 84 200 1 1 0 0 10 20 25 200 4 4


rem *****
rem Ex 5. - Produces staccato note events by setting the note duration range 
rem	between 0.1 and 0.2 and a higher grppakhi

rem minoutdur packing scatter tgrid 
rem sndf sndl ming maxg mind maxd minp maxp 
rem phgrid gpspace gpsprange amprise contour 
rem gpsizelo gpsizehi gppaklo gppakhi gpranglo gpranghi

texture grouped 3 horn groupex5 ndfgrp1.txt 12 2  0 0 1 1  30 64 0.1 0.2 36 84 200 1 1 0 0 10 20 25 300 4 4


rem *****
rem Ex 6. - Produces some group overlap (blending) by reducing packing 
rem 	to 0.5, keeping durations short (0.2 to 0.3), resetting phgrid to 
rem 	0 (taking away the regularity)  and restoring grppakhi to 0.05 
rem	(restores rapid-fire events)

rem minoutdur packing scatter tgrid 
rem sndf sndl ming maxg mind maxd minp maxp 
rem phgrid gpspace gpsprange amprise contour 
rem gpsizelo gpsizehi gppaklo gppakhi gpranglo gpranghi

texture grouped 3 horn groupex6 ndfgrp1.txt 12 0.5  0 0 1 1  30 64 0.2 0.3 36 84 0 1 1 0 0 10 20 25 50 4 4

echo off

prompt $P$G

