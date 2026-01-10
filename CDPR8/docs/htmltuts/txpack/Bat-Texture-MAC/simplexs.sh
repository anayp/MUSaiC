#!/bin/bash

echo  SIMPLEXS.BAT - list of batch files for TEXTURE SIMPLE examples
echo  RENAME FILE EXTENSION TO .bat TO RUN \(make sure you\'ve created all 
echo	the required note data files, if not supplied with this batch file\)
echo infile:  horn.aiff as in Theocharidis\' GrainMill tutorial 
echo ndfs: ndfsim1.txt, ndfsim2.txt, ndfsim3.txt, ndfsim4.txt, 
echo	ndfsim5.txt, ndfsim6.txt, ndfsim7.txt, ndfsim8.txt
echo time-varying parameters:  packchng.brk, simplpak.brk grplo.brk, grphi.brk

echo A Endrich - last updated 24 July 2000

echo 

echo set CDP_SOUND_EXT.aiff
set CDP_SOUND_EXT.aiff
echo 

echo *****
echo Ex 1a.  Produces a note repeating at the 1/4 sec, with 
echo	overlaps and \(irregular\) alternations between speakers
echo  Uses ndfsim1.txt as note data file \(\'ndf\'\), containing only the 
echo	real or supposed \(MIDI\) pitch of the infile \(60 in this case\)
echo 

echo Ex 1b. Uses time-varying packing as in packchng.txt as follows:
echo 0  0.025
echo 3  0.1
echo 6  0.05
echo 9  0.25
echo 12 0.025
echo 

echo group function mode infile outfile ndf outdur  packing scatter tgrid 
echo	snd1st sndlast  mingain maxgain  mindur maxdur  minpich maxpich
echo 

echo texture simple 5 horn simplex1a ndfsim1.txt 12 0.25 0 0 1 1 36 84 0.2 1.5 60 60
texture simple 5 horn simplex1a ndfsim1.txt 12 0.25 0 0 1 1 36 84 0.2 1.5 60 60
echo texture simple 5 horn simplex1b ndfsim1.txt 12 packchng.brk 0 0 1 1 36 84 0.2 1.5 60 60
texture simple 5 horn simplex1b ndfsim1.txt 12 packchng.brk 0 0 1 1 36 84 0.2 1.5 60 60
echo 

echo 

echo *****
echo Ex 2. Produces a rapid-fire perfect fifth interval
echo The ndf ndfsim2.txt defines two note events:
echo 60
echo \#2
echo 0 1 60 0 0
echo 0 1 67 0 0
echo 

echo group function mode infile outfile ndf outdur  packing scatter tgrid 
echo	snd1st sndlast  mingain maxgain  mindur maxdur  minpich maxpich
echo 

echo texture simple 3 horn simplex2 ndfsim2.txt 12 0.025 0 0 1 1 36 84 0.2 1.5 60 67
texture simple 3 horn simplex2 ndfsim2.txt 12 0.025 0 0 1 1 36 84 0.2 1.5 60 67
echo 

echo 

echo *****
echo Ex 3A. Produces a multi-note-texture on a defined set of pitches
echo Ex 3B. Mode 2 draws from different 8ves, but note repeats when 
echo	constrained to the pitch range and can\'t get at a given octave
echo Ex 3C. Wider pitch range opens it out
echo 

echo The ndfs ndfsim3a/b.txt contains 4 note events:
echo ndfsim3a.txt	ndfsim3b.txt \(changing times - use Mode 2 or 4\)
echo 60			60
echo \#4		\#4
echo 0 1 60 0 0		0  1 60 0 0
echo 0 1 67 0 0		4  1 67 0 0
echo 0 1 72 0 0		7  1 72 0 0
echo 0 1 76 0 0		11 1 76 0 0
echo 

echo group function mode infile outfile ndf outdur  packing scatter tgrid 
echo	snd1st sndlast  mingain maxgain  mindur maxdur  minpich maxpich
echo 

echo texture simple 3 horn simplex3a ndfsim3a.txt 12 0.25 0 0 1 1 36 84 .2 1.5 60 76
texture simple 3 horn simplex3a ndfsim3a.txt 12 0.25 0 0 1 1 36 84 .2 1.5 60 76
echo texture simple 2 horn simplex3b ndfsim3b.txt 12 0.25 0 0 1 1 36 84 .2 1.5 60 76
texture simple 2 horn simplex3b ndfsim3b.txt 12 0.25 0 0 1 1 36 84 .2 1.5 60 76
echo texture simple 2 horn simplex3c ndfsim3b.txt 12 0.25 0 0 1 1 36 84 .2 1.5 36 96
texture simple 2 horn simplex3c ndfsim3b.txt 12 0.25 0 0 1 1 36 84 .2 1.5 36 96
echo 

echo 

echo *****
echo Ex 4a. Produces a texture on a 4-note chord which changes from major 
echo	to minor \(10th\)
echo Ex 4b. Shows what happens when the packing is reduced to 0.025
echo Ex 4c. Additional timing variants.
echo 

echo The ndfs ndfsim4a/b.txt contains 8 note events:
echo ndfsim4a.txt	ndfsim4b.txt
echo 60			rem 60
echo \#8		\#8
echo 0 1 60 0 0		0  1 60 0 0
echo 0 1 67 0 0		0  1 67 0 0
echo 0 1 72 0 0		0  1 72 0 0
echo 0 1 76 0 0		0  1 76 0 0
echo 6 1 60 0 0		6  1 60 0 0
echo 6 1 67 0 0		8  1 67 0 0
echo 6 1 72 0 0		10 1 67 0 0
echo 6 1 75 0 0		10 1 67 0 0
echo 

echo group function mode infile outfile ndf outdur  packing scatter tgrid 
echo	snd1st sndlast  mingain maxgain  mindur maxdur  minpich maxpich
echo 

echo texture simple 4 horn simplex4a ndfsim4a.txt 12 0.25  0 0 1 1 36 84 .2 1.5 60 76
texture simple 4 horn simplex4a ndfsim4a.txt 12 0.25  0 0 1 1 36 84 .2 1.5 60 76
echo texture simple 4 horn simplex4b ndfsim4a.txt 12 0.025 0 0 1 1 36 84 .2 1.5 60 76
texture simple 4 horn simplex4b ndfsim4a.txt 12 0.025 0 0 1 1 36 84 .2 1.5 60 76
echo texture simple 4 horn simplex4c ndfsim4b.txt 12 0.025 0 0 1 1 36 84 .2 1.5 60 76
texture simple 4 horn simplex4c ndfsim4b.txt 12 0.025 0 0 1 1 36 84 .2 1.5 60 76
echo 

echo 

echo *****
echo Ex 5.  Produces a resonant melody
echo	note the use of the -w flag:  always uses whole duration of infile
echo 

echo The ndf ndfsim5.txt is as follows:
echo 60
echo \#10
echo 0.0  1 60 0 0
echo 1.0  1 67 0 0
echo 3.0  1 66 0 0
echo 3.5  1 62 0 0
echo 4.5  1 64 0 0
echo 6.0  1 69 0 0
echo 7.5  1 66 0 0
echo 8.5  1 60 0 0
echo 9.5  1 62 0 0
echo 10.0 1 67 0 0
echo 

echo group function mode infile outfile ndf outdur  packing scatter tgrid 
echo	snd1st sndlast  mingain maxgain  mindur maxdur  minpich maxpich
echo 

echo texture simple 4 horn simplex5 ndfsim5.txt 12 0.4 0.3 0 1 1 36 84 0.2 1.5 60 69 -w
texture simple 4 horn simplex5 ndfsim5.txt 12 0.4 0.3 0 1 1 36 84 0.2 1.5 60 69 -w
echo 

echo 

echo Ex 6.  time-varying \(enveloped\) texture shapes:  expanding up/down 
echo	and back;  then full up/down compressing towards the centre
echo 

echo the files are:
echo ndfsim6.txt		simplpak.brk	gprlo.brk	gprhi.brk
echo 60			0     0.25	0     60	0     60
echo \#22		5     0.1	5     49	5     70
echo 0.0  1 49 0 0	10    0.3	10    60	10    60
echo 0.0  1 52 0 0   	10.01 0.05	10.01 58	10.01 78
echo 0.0  1 54 0 0	18    0.15	18    67	18    67
echo 0.0  1 55 0 0	20    0.25	20    67	20    67
echo 0.0  1 58 0 0
echo 0.0  1 60 0 0
echo 0.0  1 61 0 0
echo 0.0  1 64 0 0
echo 0.0  1 66 0 0
echo 0.0  1 67 0 0
echo 0.0  1 70 0 0
echo 10.0 1 58 0 0
echo 10.0 1 60 0 0
echo 10.0 1 61 0 0
echo 10.0 1 64 0 0
echo 10.0 1 66 0 0
echo 10.0 1 67 0 0
echo 10.0 1 70 0 0
echo 10.0 1 72 0 0
echo 10.0 1 73 0 0
echo 10.0 1 76 0 0
echo 10.0 1 78 0 0
echo 

echo texture simple 3 horn simplex6 ndfsim6.txt 21 simplpak.brk 0 0 1 1 40 80 0.2 1.5 gprlo.brk gprhi.brk
texture simple 3 horn simplex6 ndfsim6.txt 21 simplpak.brk 0 0 1 1 40 80 0.2 1.5 gprlo.brk gprhi.brk
echo 


