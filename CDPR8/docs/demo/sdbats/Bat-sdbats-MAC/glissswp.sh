#!/bin/bash

echo  glissswp.bat - Batch File for a processing sequence that
echo	produces a complex glissing, blurred sweeping sound
echo  4th Sound-Builder Template
echo Source: asrcmix.aiff \(basic, complex source sound\)
echo Use glisssdel.bat to DELETE remaining files

echo 

echo Step 1 - COPY TO GENERIC NAME
echo copysfx asrcmix.aiff d.aiff
copysfx asrcmix.aiff d.aiff
echo 

echo Step 2- ANALYSE
echo pvoc anal 1 d.aiff d.ana
pvoc anal 1 d.aiff d.ana
echo 

echo Step 3 - FOCUS ACCU params: delay \& gliss
echo focus accu d.ana daccu.ana -d0.9 -g0.9
focus accu d.ana daccu.ana -d0.9 -g0.9
echo RESYNTHESIS FOR AUDITION IN HTML DOCUMENT
echo pvoc synth daccu.ana daccu.aiff
pvoc synth daccu.ana daccu.aiff
echo rm d.ana
rm d.ana
echo 

echo Step 4 - BLUR BLUR param: no. of windows to blur
echo blur blur daccu.ana daccubl100.ana 100
blur blur daccu.ana daccubl100.ana 100
echo RESYNTHESIS FOR AUDITION PURPOSES IN HTML DOCUMENT
echo pvoc synth daccubl100.ana daccubl100.aiff
pvoc synth daccubl100.ana daccubl100.aiff
echo rm daccu.ana
rm daccu.ana
echo 

echo Step 5 - STRETCH TIME param: no. of times to stretch
echo stretch time 1 daccubl100.ana daccubl100x3.ana 3
stretch time 1 daccubl100.ana daccubl100x3.ana 3
echo rm daccubl100.ana
rm daccubl100.ana
echo 

echo Step 6 - RESYNTHESISE
echo pvoc synth daccubl100x3.ana daccubl100x3.aiff
pvoc synth daccubl100x3.ana daccubl100x3.aiff
echo rm daccubl100x3.ana
rm daccubl100x3.ana
echo 

echo Step 7a - TRANSPOSE IN TIME DOMAIN
echo modify speed 2 daccubl100x3 daccubl100x3d12 -12
modify speed 2 daccubl100x3 daccubl100x3d12 -12
echo Result 1: complex, glissing entity
paplay daccubl100x3d12.aiff.aiff
echo 

echo OR:
echo Step 7b - FILTER SWEEPING Mode 3 = Band Pass, Mode 2 = Low Pass
echo FILTER SWEEPING params: acuity gain lof hig sweepfrq [phase .25]
echo filter sweeping 2 daccubl100x3 daccubl100x3swp .5 .4 100 2000 0.25
filter sweeping 2 daccubl100x3 daccubl100x3swp .5 .4 100 2000 0.25
echo 

echo Step 8 - TRANSPOSE IN TIME DOMAIN
echo modify speed 2 daccubl100x3swp daccubl100x3swpd12 -12
modify speed 2 daccubl100x3swp daccubl100x3swpd12 -12
echo Result 2: complex glissing entity, subtler and 
echo	smoother than Result 1.
paplay daccubl100x3swpd12.aiff.aiff
echo 


