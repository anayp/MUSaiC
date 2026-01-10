prompt $G

rem grnfldel.bat - deletions for grnflow.bat, 
rem  3rd Sound-Builder Template
rem These deletions include the GrainMill files made using the 
rem   graphic program.  If they haven't been made, they simply won't 
rem   be found by this deletions batch file.

echo on

del c1.wav
del c2.wav
del c1.ana
del c2.ana

del cer.wav
del ci.ana
del ci.wav
del cm.ana
del cm.wav

del cmcicer.wav

del cmcicerflth.wav
rem del cmcicerflta.wav
rem del cmcicerflts.wav

del cmcicerflthgrn.wav
del cmcicerflthgm1.wav
del cmcicerflthgm2.wav

del cmcicerflthgrn.ana
del cmcicerflthgrnshift.ana
del cmcicerflthgrnshift.wav

del cmcicerflthgrnshiftgm3.wav
del cmcicerflthgrnshiftgm4.wav

echo off

prompt $P$G
