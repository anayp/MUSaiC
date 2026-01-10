prompt $G

rem  SIMPLEXS.BAT - list of batch files for TEXTURE SIMPLE examples
rem  RENAME FILE EXTENSION TO .bat TO RUN (make sure you've created all 
rem	the required note data files, if not supplied with this batch file)
rem infile:  horn.wav as in Theocharidis' GrainMill tutorial 
rem ndfs: ndfsim1.txt, ndfsim2.txt, ndfsim3.txt, ndfsim4.txt, 
rem	ndfsim5.txt, ndfsim6.txt, ndfsim7.txt, ndfsim8.txt
rem time-varying parameters:  packchng.brk, simplpak.brk grplo.brk, grphi.brk

rem A Endrich - last updated 24 July 2000

echo on

set CDP_SOUND_EXT=wav

rem *****
rem Ex 1a.  Produces a note repeating at the 1/4 sec, with 
rem	overlaps and (irregular) alternations between speakers
rem  Uses ndfsim1.txt as note data file ('ndf'), containing only the 
rem	real or supposed (MIDI) pitch of the infile (60 in this case)

rem Ex 1b. Uses time-varying packing as in packchng.txt as follows:
rem 0  0.025
rem 3  0.1
rem 6  0.05
rem 9  0.25
rem 12 0.025

rem group function mode infile outfile ndf outdur  packing scatter tgrid 
rem	snd1st sndlast  mingain maxgain  mindur maxdur  minpich maxpich

texture simple 5 horn simplex1a ndfsim1.txt 12 0.25 0 0 1 1 36 84 0.2 1.5 60 60
texture simple 5 horn simplex1b ndfsim1.txt 12 packchng.brk 0 0 1 1 36 84 0.2 1.5 60 60


rem *****
rem Ex 2. Produces a rapid-fire perfect fifth interval
rem The ndf ndfsim2.txt defines two note events:
rem 60
rem #2
rem 0 1 60 0 0
rem 0 1 67 0 0

rem group function mode infile outfile ndf outdur  packing scatter tgrid 
rem	snd1st sndlast  mingain maxgain  mindur maxdur  minpich maxpich

texture simple 3 horn simplex2 ndfsim2.txt 12 0.025 0 0 1 1 36 84 0.2 1.5 60 67


rem *****
rem Ex 3A. Produces a multi-note-texture on a defined set of pitches
rem Ex 3B. Mode 2 draws from different 8ves, but note repeats when 
rem	constrained to the pitch range and can't get at a given octave
rem Ex 3C. Wider pitch range opens it out

rem The ndfs ndfsim3a/b.txt contains 4 note events:
rem ndfsim3a.txt	ndfsim3b.txt (changing times - use Mode 2 or 4)
rem 60			60
rem #4			#4
rem 0 1 60 0 0		0  1 60 0 0
rem 0 1 67 0 0		4  1 67 0 0
rem 0 1 72 0 0		7  1 72 0 0
rem 0 1 76 0 0		11 1 76 0 0

rem group function mode infile outfile ndf outdur  packing scatter tgrid 
rem	snd1st sndlast  mingain maxgain  mindur maxdur  minpich maxpich

texture simple 3 horn simplex3a ndfsim3a.txt 12 0.25 0 0 1 1 36 84 .2 1.5 60 76
texture simple 2 horn simplex3b ndfsim3b.txt 12 0.25 0 0 1 1 36 84 .2 1.5 60 76
texture simple 2 horn simplex3c ndfsim3b.txt 12 0.25 0 0 1 1 36 84 .2 1.5 36 96


rem *****
rem Ex 4a. Produces a texture on a 4-note chord which changes from major 
rem	to minor (10th)
rem Ex 4b. Shows what happens when the packing is reduced to 0.025
rem Ex 4c. Additional timing variants.

rem The ndfs ndfsim4a/b.txt contains 8 note events:
rem ndfsim4a.txt	ndfsim4b.txt
rem 60			rem 60
rem #8			#8
rem 0 1 60 0 0		0  1 60 0 0
rem 0 1 67 0 0		0  1 67 0 0
rem 0 1 72 0 0		0  1 72 0 0
rem 0 1 76 0 0		0  1 76 0 0
rem 6 1 60 0 0		6  1 60 0 0
rem 6 1 67 0 0		8  1 67 0 0
rem 6 1 72 0 0		10 1 67 0 0
rem 6 1 75 0 0		10 1 67 0 0

rem group function mode infile outfile ndf outdur  packing scatter tgrid 
rem	snd1st sndlast  mingain maxgain  mindur maxdur  minpich maxpich

texture simple 4 horn simplex4a ndfsim4a.txt 12 0.25  0 0 1 1 36 84 .2 1.5 60 76
texture simple 4 horn simplex4b ndfsim4a.txt 12 0.025 0 0 1 1 36 84 .2 1.5 60 76
texture simple 4 horn simplex4c ndfsim4b.txt 12 0.025 0 0 1 1 36 84 .2 1.5 60 76


rem *****
rem Ex 5.  Produces a resonant melody
rem	note the use of the -w flag:  always uses whole duration of infile

rem The ndf ndfsim5.txt is as follows:
rem 60
rem #10
rem 0.0  1 60 0 0
rem 1.0  1 67 0 0
rem 3.0  1 66 0 0
rem 3.5  1 62 0 0
rem 4.5  1 64 0 0
rem 6.0  1 69 0 0
rem 7.5  1 66 0 0
rem 8.5  1 60 0 0
rem 9.5  1 62 0 0
rem 10.0 1 67 0 0

rem group function mode infile outfile ndf outdur  packing scatter tgrid 
rem	snd1st sndlast  mingain maxgain  mindur maxdur  minpich maxpich

texture simple 4 horn simplex5 ndfsim5.txt 12 0.4 0.3 0 1 1 36 84 0.2 1.5 60 69 -w


rem Ex 6.  time-varying (enveloped) texture shapes:  expanding up/down 
rem	and back;  then full up/down compressing towards the centre

rem the files are:
rem ndfsim6.txt		simplpak.brk	gprlo.brk	gprhi.brk
rem 60			0     0.25	0     60	0     60
rem #22			5     0.1	5     49	5     70
rem 0.0  1 49 0 0	10    0.3	10    60	10    60
rem 0.0  1 52 0 0   	10.01 0.05	10.01 58	10.01 78
rem 0.0  1 54 0 0	18    0.15	18    67	18    67
rem 0.0  1 55 0 0	20    0.25	20    67	20    67
rem 0.0  1 58 0 0
rem 0.0  1 60 0 0
rem 0.0  1 61 0 0
rem 0.0  1 64 0 0
rem 0.0  1 66 0 0
rem 0.0  1 67 0 0
rem 0.0  1 70 0 0
rem 10.0 1 58 0 0
rem 10.0 1 60 0 0
rem 10.0 1 61 0 0
rem 10.0 1 64 0 0
rem 10.0 1 66 0 0
rem 10.0 1 67 0 0
rem 10.0 1 70 0 0
rem 10.0 1 72 0 0
rem 10.0 1 73 0 0
rem 10.0 1 76 0 0
rem 10.0 1 78 0 0

texture simple 3 horn simplex6 ndfsim6.txt 21 simplpak.brk 0 0 1 1 40 80 0.2 1.5 gprlo.brk gprhi.brk

echo off

prompt $P$G
