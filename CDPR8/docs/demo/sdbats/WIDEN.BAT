prompt $G

rem widen.bat - batch file to widen a sound with adjacent 
rem   transpositions;  forms Sound-Builder Template 6
rem very tight transpositions give the sound a resonant 
rem   aura, but wider transpositions start to produce 
rem   beats

echo on

rem STEP 1. COPY TO GENERIC NAME
copysfx asrcmix.wav f.wav

rem STEP 2. ANALYSE 
pvoc anal 1 f f.ana

rem STEP 3. TRANSPOSE UP (retaining same length)
repitch transpose 3 f.ana fupabit.ana 1.0
pvoc synth fupabit.ana fupabit.wav
del fupabit.ana

rem STEP 4. TRANSPOSE DOWN (retaining same length)
repitch transpose 3 f.ana fdownabit.ana -1.0
pvoc synth fdownabit.ana fdownabit.wav
del f.ana
del fdownabit.ana

rem STEP 5. MIX IT ALL TOGETHER
submix mix widentrn.mix fwider.wav

echo off

prompt $P$G
