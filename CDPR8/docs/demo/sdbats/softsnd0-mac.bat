# softsnd0-mac.bat - template batch file for creating a 'soft' 
#	sound (soft, extended attack & a long fade)
# use softdels-mac.bat to delete mspx6x32/c/cg/cgdt .wav files

# INFILE:  e.g., marimba.wav (1.002 sec, 44100 mono)
# 	     may get some *very* soft washes if start with a sound 
#	     which has a soft attack to start with

echo on

# PRE-PROCESSING
# to re-run with a different input, just change the anal line and 
# the final rename line (e.g., change the 1 to a 2, etc.)

pvoc anal 1 whdtm m.ana

# SOUND TRANSFORMATION SEQUENCE
# SPECTRUM-STRETCH
stretch spectrum 2 m.ana mspx6.ana 1000 6 0.4 -d1
pvoc synth mspx6.ana mspx6
paplay mspx6

# TIME-STRETCH (x16 in 4 steps)
stretch time 1 mspx6.ana mspx6tx2.ana 2
rm mspx6.ana

stretch time 1 mspx6tx2.ana mspx6tx4.ana 2
rm mspx6tx2.ana

#  NB: ensure cut points accord with length of input
spec cut mspx6tx4.ana mspx6tx4c.ana 0 2
rm mspx6tx4.ana

stretch time 1 mspx6tx4c.ana mspx6tx8.ana 2
rm mspx6tx4c.ana

spec cut mspx6tx8.ana mspx6tx8c.ana 0 3
rm mspx6tx8.ana

stretch time 1 mspx6tx8c.ana mspx6tx16.ana 2
rm mspx6tx8c.ana

spec cut mspx6tx16.ana mspx6tx16c.ana 0 3
rm mspx6tx16.ana

SYNTHESISE
pvoc synth mspx6tx16c.ana mspx6tx16c
rm mspx6tx16c.ana

(GAIN REDUCTION &) DOVETAIL
modify loudness 1 mspx6tx16c mspx6tx16cg 1
env dovetail mspx6tx16cg mspx6tx16cgdt 0.2 1 0 0

ren mspx6tx16cgdt.wav msoft.wav
paplay msoft

# OPTIONAL STRETCH TO 32x
# stretch time 1 mspx6tx16c.ana mspx6tx32.ana 2
# rm mspx6tx16c.ana
# spec cut mspx6tx32.ana mspx6tx32c.ana 0 3
# rm mspx6tx32.ana

# SYNTHESISE
# pvoc synth mspx6tx32c.ana mspx6tx32c
# rm mspx6tx32c.ana

echo off
