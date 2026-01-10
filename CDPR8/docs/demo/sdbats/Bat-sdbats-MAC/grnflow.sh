#!/bin/bash

echo grnflow.bat - \'GRAINFLOW\' batch file for 3rd 
echo  Sound-Builder Template
echo Description: multiple file operations combined, 
echo  filtered \& granulated
echo Use grnfldel.bat to delete remaining files between uses
echo Last updated: 28 March 2003

echo Source Pairs:
echo   aklcdp.aiff  \(1.38 sec\) \& tomcdt.aiff  \(1.3 sec\) - rhythms good
echo   frogcdt.aiff \(1.8 sec\)  \& bashdt.aiff  \(1.5 sec\) - frogs good
echo   touccdt.aiff \(3.0 sec\)  \& hoggdt.aiff  \(3.7 sec\) - toucan audible
echo   touccdt.aiff \(3.0 sec\)  \& whdtm.aiff   \(2.4 sec\) - steadier high pitch


echo 

echo COPY to generic name
echo copysfx frogcdt.aiff c1.aiff
copysfx frogcdt.aiff c1.aiff
echo copysfx bashdt.aiff c2.aiff
copysfx bashdt.aiff c2.aiff
echo 

echo pvoc anal 1 c c1.ana
pvoc anal 1 c c1.ana
echo pvoc anal 1 c2 c2.ana
pvoc anal 1 c2 c2.ana
echo 

echo REPLACE c2\'s ENVELOPE with c1\'s
echo envel replace 1 c2 c1 cer 10
envel replace 1 c2 c1 cer 10
echo 

echo INTERLEAVE c1 \& c2
echo combine interleave c1.ana c2.ana ci.ana 10
combine interleave c1.ana c2.ana ci.ana 10
echo pvoc synth ci.ana ci
pvoc synth ci.ana ci
echo 

echo RANDOM MIX based on max amplitude, on window-to-window basis
echo combine max c1.ana c2.ana cm.ana
combine max c1.ana c2.ana cm.ana
echo pvoc synth cm.ana cm
pvoc synth cm.ana cm
echo 

echo SPLICE the three results together: cm+ci+cer in that order
echo sfedit join cm ci cer cmcicer
sfedit join cm ci cer cmcicer
echo 

echo FILTER, using pre-edited \& existing filterbank data file
echo \(Otherwise create with FILTER BANKFREQS, 100-2000Hz\)
echo cmcicer3h.txt \(HARMONIC\) cmcicer3a.txt \(ALT HARMONICS\) or 
echo    cmcicer3s.txt \(SUBHARMONIC\).
echo filter userbank 1 cmcicer cmcicerflth cmcicer3h.txt 100 5
filter userbank 1 cmcicer cmcicerflth cmcicer3h.txt 100 5
echo 

echo GRANULATE \(only using density parameter\)
echo modify brassage 5 cmcicerflth cmcicerflthgrn 2
modify brassage 5 cmcicerflth cmcicerflthgrn 2
echo 

echo GRANULATE WITH GrainMill, opening cmcicerflth.aiff \(or another 
echo   soundfile\) and loading day3gm1.grn \(if able to do so\). 
echo   See day3gm1.txt for ascii version.
echo   Outfile is cmcicerflthgm1.aiff \(cmcicerflthgm2.aiff with pitch 
echo   range settings, e.g., +7 \& -5 to give octave spread\)
echo 

echo Time-varying spectral SHIFT
echo \(NB: check that timings in shift2 .brk match infile length\)
echo pvoc anal 1 cmcicerflthgrn.aiff cmcicerflthgrn.ana
pvoc anal 1 cmcicerflthgrn.aiff cmcicerflthgrn.ana
echo strange shift 1 cmcicerflthgrn.ana cmcicerflthgrnshift.ana shift2.brk
strange shift 1 cmcicerflthgrn.ana cmcicerflthgrnshift.ana shift2.brk
echo 

echo RESYNTHESISE the shifted analysis file
echo pvoc synth cmcicerflthgrnshift.ana cmcicerflthgrnshift.aiff
pvoc synth cmcicerflthgrnshift.ana cmcicerflthgrnshift.aiff
echo 

echo GRANULATE WITH GrainMill opening cmcicerflthgrnshift.aiff and 
echo   re-loading \(if possible\) day3gm1.grn.
echo   Outfile\(s\) can be named cmcicerflthgrnshiftgm3.aiff and 
echo   cmcicerflthgrnshiftgm4.aiff
echo 




