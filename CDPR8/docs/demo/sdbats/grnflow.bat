prompt $G

rem grnflow.bat - 'GRAINFLOW' batch file for 3rd 
rem  Sound-Builder Template
rem Description: multiple file operations combined, 
rem  filtered & granulated
rem Use grnfldel.bat to delete remaining files between uses
rem Last updated: 28 March 2003

rem Source Pairs:
rem   aklcdp.wav  (1.38 sec) & tomcdt.wav  (1.3 sec) - rhythms good
rem   frogcdt.wav (1.8 sec)  & bashdt.wav  (1.5 sec) - frogs good
rem   touccdt.wav (3.0 sec)  & hoggdt.wav  (3.7 sec) - toucan audible
rem   touccdt.wav (3.0 sec)  & whdtm.wav   (2.4 sec) - steadier high pitch


echo on

rem COPY to generic name
copysfx frogcdt.wav c1.wav
copysfx bashdt.wav c2.wav

pvoc anal 1 c c1.ana
pvoc anal 1 c2 c2.ana

rem REPLACE c2's ENVELOPE with c1's
envel replace 1 c2 c1 cer 10

rem INTERLEAVE c1 & c2
combine interleave c1.ana c2.ana ci.ana 10
pvoc synth ci.ana ci

rem RANDOM MIX based on max amplitude, on window-to-window basis
combine max c1.ana c2.ana cm.ana
pvoc synth cm.ana cm

rem SPLICE the three results together: cm+ci+cer in that order
sfedit join cm ci cer cmcicer

rem FILTER, using pre-edited & existing filterbank data file
rem (Otherwise create with FILTER BANKFREQS, 100-2000Hz)
rem cmcicer3h.txt (HARMONIC) cmcicer3a.txt (ALT HARMONICS) or 
rem    cmcicer3s.txt (SUBHARMONIC).
filter userbank 1 cmcicer cmcicerflth cmcicer3h.txt 100 5

rem GRANULATE (only using density parameter)
modify brassage 5 cmcicerflth cmcicerflthgrn 2

rem GRANULATE WITH GrainMill, opening cmcicerflth.wav (or another 
rem   soundfile) and loading day3gm1.grn (if able to do so). 
rem   See day3gm1.txt for ascii version.
rem   Outfile is cmcicerflthgm1.wav (cmcicerflthgm2.wav with pitch 
rem   range settings, e.g., +7 & -5 to give octave spread)

rem Time-varying spectral SHIFT
rem (NB: check that timings in shift2 .brk match infile length)
pvoc anal 1 cmcicerflthgrn.wav cmcicerflthgrn.ana
strange shift 1 cmcicerflthgrn.ana cmcicerflthgrnshift.ana shift2.brk

rem RESYNTHESISE the shifted analysis file
pvoc synth cmcicerflthgrnshift.ana cmcicerflthgrnshift.wav

rem GRANULATE WITH GrainMill opening cmcicerflthgrnshift.wav and 
rem   re-loading (if possible) day3gm1.grn.
rem   Outfile(s) can be named cmcicerflthgrnshiftgm3.wav and 
rem   cmcicerflthgrnshiftgm4.wav

echo off

prompt $P$G


