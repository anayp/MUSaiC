rem softsnd0.bat - template batch file for creating a 'soft' 
rem	sound (soft, extended attack & a long fade)
rem use softdels.bat to delete mspx6x32/c/cg/cgdt .wav files

rem INFILE:  e.g., marimba.wav (1.002 sec, 44100 mono)
rem 	     may get some *very* soft washes if start with a sound 
rem	     which has a soft attack to start with

echo on

rem PRE-PROCESSING
rem to re-run with a different input, just change the anal line and 
rem the final rename line (e.g., change the 1 to a 2, etc.)

pvoc anal 1 whdtm m.ana

rem SOUND TRANSFORMATION SEQUENCE
rem SPECTRUM-STRETCH
stretch spectrum 2 m.ana mspx6.ana 1000 6 0.4 -d1
pvoc synth mspx6.ana mspx6
playsfx mspx6

rem TIME-STRETCH (x16 in 4 steps)
stretch time 1 mspx6.ana mspx6tx2.ana 2
del mspx6.ana

stretch time 1 mspx6tx2.ana mspx6tx4.ana 2
del mspx6tx2.ana

REM  NB: ensure cut points accord with length of input
spec cut mspx6tx4.ana mspx6tx4c.ana 0 2
del mspx6tx4.ana

stretch time 1 mspx6tx4c.ana mspx6tx8.ana 2
del mspx6tx4c.ana

spec cut mspx6tx8.ana mspx6tx8c.ana 0 3
del mspx6tx8.ana

stretch time 1 mspx6tx8c.ana mspx6tx16.ana 2
del mspx6tx8c.ana

spec cut mspx6tx16.ana mspx6tx16c.ana 0 3
del mspx6tx16.ana

SYNTHESISE
pvoc synth mspx6tx16c.ana mspx6tx16c
del mspx6tx16c.ana

(GAIN REDUCTION &) DOVETAIL
modify loudness 1 mspx6tx16c mspx6tx16cg 1
env dovetail mspx6tx16cg mspx6tx16cgdt 0.2 1 0 0

ren mspx6tx16cgdt.wav msoft.wav
playsfx msoft

rem OPTIONAL STRETCH TO 32x
rem stretch time 1 mspx6tx16c.ana mspx6tx32.ana 2
rem del mspx6tx16c.ana
rem spec cut mspx6tx32.ana mspx6tx32c.ana 0 3
rem del mspx6tx32.ana

rem SYNTHESISE
rem pvoc synth mspx6tx32c.ana mspx6tx32c
rem del mspx6tx32c.ana

echo off
