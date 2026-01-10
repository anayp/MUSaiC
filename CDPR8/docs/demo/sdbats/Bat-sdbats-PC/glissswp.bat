prompt $G

rem  glissswp.bat - Batch File for a processing sequence that
rem	produces a complex glissing, blurred sweeping sound
rem  4th Sound-Builder Template
rem Source: asrcmix.wav (basic, complex source sound)
rem Use glisssdel.bat to DELETE remaining files

echo on

rem Step 1 - COPY TO GENERIC NAME
copysfx asrcmix.wav d.wav

rem Step 2- ANALYSE
pvoc anal 1 d.wav d.ana

rem Step 3 - FOCUS ACCU params: delay & gliss
focus accu d.ana daccu.ana -d0.9 -g0.9
rem RESYNTHESIS FOR AUDITION IN HTML DOCUMENT
pvoc synth daccu.ana daccu.wav
del d.ana

rem Step 4 - BLUR BLUR param: no. of windows to blur
blur blur daccu.ana daccubl100.ana 100
rem RESYNTHESIS FOR AUDITION PURPOSES IN HTML DOCUMENT
pvoc synth daccubl100.ana daccubl100.wav
del daccu.ana

rem Step 5 - STRETCH TIME param: no. of times to stretch
stretch time 1 daccubl100.ana daccubl100x3.ana 3
del daccubl100.ana

rem Step 6 - RESYNTHESISE
pvoc synth daccubl100x3.ana daccubl100x3.wav
del daccubl100x3.ana

rem Step 7a - TRANSPOSE IN TIME DOMAIN
modify speed 2 daccubl100x3 daccubl100x3d12 -12
rem Result 1: complex, glissing entity
playsfx daccubl100x3d12.wav

rem OR:
rem Step 7b - FILTER SWEEPING Mode 3 = Band Pass, Mode 2 = Low Pass
rem FILTER SWEEPING params: acuity gain lof hig sweepfrq [phase .25]
filter sweeping 2 daccubl100x3 daccubl100x3swp .5 .4 100 2000 0.25

rem Step 8 - TRANSPOSE IN TIME DOMAIN
modify speed 2 daccubl100x3swp daccubl100x3swpd12 -12
rem Result 2: complex glissing entity, subtler and 
rem	smoother than Result 1.
playsfx daccubl100x3swpd12.wav

echo off

prompt $P$G
