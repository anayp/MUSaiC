prompt $G

rem churbles.bat - 'CHURBLES' batch file for reentry.htm, 
rem  2nd Sound-Builder Template
rem Description: usually results in lightly churning burbles
rem Use churbdel.bat to Delete remaining files beteween uses
rem Last updated: 24 March 2003

rem Sources:
rem   aklcdp.wav  (1.38 sec) - good rhythms & sonic changes
rem   bashdt.wav  (1.5 sec) - not good, too similar all through
rem   frogcdt.wav (1.8 sec) - excellent because spreads attack
rem   hoggdt.wav  (3.7 sec) - churning then lighter burbles
rem   tomcdt.wav  (1.3 sec) - remarkably good: goes very thin
	(it's the ring modulation that makes the biggest change)
rem   touccdt.wav (3.0 sec) - distortion very prominent
rem   whdtm.wav   (2.4 sec) - light randomised churning

echo on

rem Copy to simple name
copysfx aklcdt.wav b.wav

rem Distort Repeat x cycles in y groups
distort repeat b bdr 5 -c2

rem Ring Modulate
modify radical 5 bdr bdrrm 1000

rem Loop with longish overlapping segments
extend loop 1 bdrrm bdrrmloop 0.0 500 100

rem Scramble the file of loops
extend scramble 1 bdrrmloop bdrrmloopscr 0.06 1.1 32 -w25

rem Analyse
pvoc anal 1 bdrrmloopscr bdrrmloopscr.ana

rem Trace to reduce to n loudest partials
hilite trace 1  bdrrmloopscr.ana  bdrrmloopscrtr.ana 10

rem Synthesise final result
pvoc synth  bdrrmloopscrtr.ana  bdrrmloopscrtr

echo off

prompt $P$G
