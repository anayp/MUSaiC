#!/bin/bash

echo churbles.bat - \'CHURBLES\' batch file for reentry.htm, 
echo  2nd Sound-Builder Template
echo Description: usually results in lightly churning burbles
echo Use churbdel.bat to Delete remaining files beteween uses
echo Last updated: 24 March 2003

echo Sources:
echo   aklcdp.aiff  \(1.38 sec\) - good rhythms \& sonic changes
echo   bashdt.aiff  \(1.5 sec\) - not good, too similar all through
echo   frogcdt.aiff \(1.8 sec\) - excellent because spreads attack
echo   hoggdt.aiff  \(3.7 sec\) - churning then lighter burbles
echo   tomcdt.aiff  \(1.3 sec\) - remarkably good: goes very thin
	\(it\'s the ring modulation that makes the biggest change\)
echo   touccdt.aiff \(3.0 sec\) - distortion very prominent
echo   whdtm.aiff   \(2.4 sec\) - light randomised churning

echo 

echo Copy to simple name
echo copysfx aklcdp.aiff b.aiff
copysfx aklcdp.aiff b.aiff
echo 

echo Distort Repeat x cycles in y groups
echo distort repeat b bdr 5 -c2
distort repeat b bdr 5 -c2
echo 

echo Ring Modulate
echo modify radical 5 bdr bdrrm 1000
modify radical 5 bdr bdrrm 1000
echo 

echo Loop with longish overlapping segments
echo extend loop 1 bdrrm bdrrmloop 0.0 500 100
extend loop 1 bdrrm bdrrmloop 0.0 500 100
echo 

echo Scramble the file of loops
echo extend scramble 1 bdrrmloop bdrrmloopscr 0.06 1.1 32 -w25
extend scramble 1 bdrrmloop bdrrmloopscr 0.06 1.1 32 -w25
echo 

echo Analyse
echo pvoc anal 1 bdrrmloopscr bdrrmloopscr.ana
pvoc anal 1 bdrrmloopscr bdrrmloopscr.ana
echo 

echo Trace to reduce to n loudest partials
echo hilite trace 1  bdrrmloopscr.ana  bdrrmloopscrtr.ana 10
hilite trace 1  bdrrmloopscr.ana  bdrrmloopscrtr.ana 10
echo 

echo Synthesise final result
echo pvoc synth  bdrrmloopscrtr.ana  bdrrmloopscrtr
pvoc synth  bdrrmloopscrtr.ana  bdrrmloopscrtr
echo 


