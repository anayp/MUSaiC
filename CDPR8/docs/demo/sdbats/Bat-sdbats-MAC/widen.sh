#!/bin/bash

echo widen.bat - batch file to widen a sound with adjacent 
echo   transpositions;  forms Sound-Builder Template 6
echo very tight transpositions give the sound a resonant 
echo   aura, but wider transpositions start to produce 
echo   beats

echo 

echo STEP 1. COPY TO GENERIC NAME
echo copysfx asrcmix.aiff f.aiff
copysfx asrcmix.aiff f.aiff
echo 

echo STEP 2. ANALYSE 
echo pvoc anal 1 f f.ana
pvoc anal 1 f f.ana
echo 

echo STEP 3. TRANSPOSE UP \(retaining same length\)
echo repitch transpose 3 f.ana fupabit.ana 1.0
repitch transpose 3 f.ana fupabit.ana 1.0
echo pvoc synth fupabit.ana fupabit.aiff
pvoc synth fupabit.ana fupabit.aiff
echo rm fupabit.ana
rm fupabit.ana
echo 

echo STEP 4. TRANSPOSE DOWN \(retaining same length\)
echo repitch transpose 3 f.ana fdownabit.ana -1.0
repitch transpose 3 f.ana fdownabit.ana -1.0
echo pvoc synth fdownabit.ana fdownabit.aiff
pvoc synth fdownabit.ana fdownabit.aiff
echo rm f.ana
rm f.ana
echo rm fdownabit.ana
rm fdownabit.ana
echo 

echo STEP 5. MIX IT ALL TOGETHER
echo submix mix widentrn.mix fwider.aiff
submix mix widentrn.mix fwider.aiff
echo 


