#!/bin/bash

echo day1.bat - \'RE-ENTRY\' - batch file using first set of programs
echo Description: long slow modulating descent of a rich sonic complex
echo Last updated: 29 Mar 2003

echo The source file should be about 2-4 sec. long, mono.
echo Consider using a softsnd bat before or after this one.
echo Sources:
echo   aklcdp.aiff  \(1.38 sec\) - rhythmic element produces good changes
echo   bashdt.aiff  \(1.5 sec\) - attack works well
echo   frogcdt.aiff \(1.8 sec\) - surprisingly good, with high-pitched 
echo	sounds at end: becomes 2\'10" long
echo   hoggdt.aiff  \(3.7 sec\) - lovely rich descent with extra high 
echo	pitched component towards end
echo   tomcdt.aiff  \(1.3 sec\) - not so good, not enough to work on
echo   touccdt.aiff \(3.0 sec\) - 
echo   whdtm.aiff   \(2.4 sec\) - from rubberswinger.aiff, only OK, not enough 
echo	differentiation

echo 

echo Copy to simple name
echo copysfx bashdt.aiff a.aiff
copysfx bashdt.aiff a.aiff
echo 

echo Reverse
echo modify radical 1 a ar
modify radical 1 a ar
echo 

echo Splice forward \& backward versions
echo sfedit join a ar arfb -b -e
sfedit join a ar arfb -b -e
echo 

echo Dovetail end of the spliced file
echo envel dovetail 1 arfb arfbdt 0.05 1.0 0 0
envel dovetail 1 arfb arfbdt 0.05 1.0 0 0
echo 

echo Analyse the spliced \& dovetailed file
echo pvoc anal 1 arfbdt arfbdt.ana
pvoc anal 1 arfbdt arfbdt.ana
echo 

echo Blur the spliced file
echo blur blur arfbdt.ana arfbdtbl50.ana 50
blur blur arfbdt.ana arfbdtbl50.ana 50
echo 

echo Time-Stretch the blurred file 2 times
echo stretch time 1 arfbdtbl50.ana arfbdtbl50x2.ana 2
stretch time 1 arfbdtbl50.ana arfbdtbl50x2.ana 2
echo 

echo Time-Stretch the blurred file 2 more times
echo stretch time 1 arfbdtbl50x2.ana arfbdtbl50x4.ana 2
stretch time 1 arfbdtbl50x2.ana arfbdtbl50x4.ana 2
echo 

echo Synthesise the 4x stretched file
echo pvoc synth arfbdtbl50x4.ana arfbdtbl50x4
pvoc synth arfbdtbl50x4.ana arfbdtbl50x4
echo 

echo Time-varied transposition \(glide down 18 semitones\)
echo modify speed 2 arfbdtbl50x4 arfbdtbl50x4tv1 atvpch1.brk
modify speed 2 arfbdtbl50x4 arfbdtbl50x4tv1 atvpch1.brk
echo 

echo Time-varied transposition \(glide down 24 semitones\)
echo modify speed 2 arfbdtbl50x4 arfbdtbl50x4tv2 atvpch2.brk
modify speed 2 arfbdtbl50x4 arfbdtbl50x4tv2 atvpch2.brk
echo 

echo Mix the two transposed versions \(spread at bottom\)
echo submix mix aftv1-2a.mix arfbdtbl50x4tv1-2mixa
submix mix aftv1-2a.mix arfbdtbl50x4tv1-2mixa
echo 

echo Mix the two transposed versions, with 2nd \& 3rd later
echo submix mix aftv1-2b.mix arfbdtbl50x4tv1-2mixb
submix mix aftv1-2b.mix arfbdtbl50x4tv1-2mixb
echo 

echo Dovetail end of the final file
echo envel dovetail 1 arfbdtbl50x4tv1-2mixb arfbdtbl50x4tv1-2mixbdt 0.05 1.0 0 0
envel dovetail 1 arfbdtbl50x4tv1-2mixb arfbdtbl50x4tv1-2mixbdt 0.05 1.0 0 0
echo 



