prompt $G

rem day1.bat - 'RE-ENTRY' - batch file using first set of programs
rem Description: long slow modulating descent of a rich sonic complex
rem Last updated: 29 Mar 2003

rem The source file should be about 2-4 sec. long, mono.
rem Consider using a softsnd bat before or after this one.
rem Sources:
rem   aklcdp.wav  (1.38 sec) - rhythmic element produces good changes
rem   bashdt.wav  (1.5 sec) - attack works well
rem   frogcdt.wav (1.8 sec) - surprisingly good, with high-pitched 
rem	  sounds at end: becomes 2'10" long
rem   hoggdt.wav  (3.7 sec) - lovely rich descent with extra high 
rem	  pitched component towards end
rem   tomcdt.wav  (1.3 sec) - not so good, not enough to work on
rem   touccdt.wav (3.0 sec) - 
rem   whdtm.wav   (2.4 sec) - from rubberswinger.wav, only OK, not enough 
rem	  differentiation

echo on

rem Copy to simple name
copysfx bashdt.wav a.wav

rem Reverse
modify radical 1 a ar

rem Splice forward & backward versions
sfedit join a ar arfb -b -e

rem Dovetail end of the spliced file
envel dovetail 1 arfb arfbdt 0.05 1.0 0 0

rem Analyse the spliced & dovetailed file
pvoc anal 1 arfbdt arfbdt.ana

rem Blur the spliced file
blur blur arfbdt.ana arfbdtbl50.ana 50

rem Time-Stretch the blurred file 2 times
stretch time 1 arfbdtbl50.ana arfbdtbl50x2.ana 2

rem Time-Stretch the blurred file 2 more times
stretch time 1 arfbdtbl50x2.ana arfbdtbl50x4.ana 2

rem Synthesise the 4x stretched file
pvoc synth arfbdtbl50x4.ana arfbdtbl50x4

rem Time-varied transposition (glide down 18 semitones)
modify speed 2 arfbdtbl50x4 arfbdtbl50x4tv1 atvpch1.brk

rem Time-varied transposition (glide down 24 semitones)
modify speed 2 arfbdtbl50x4 arfbdtbl50x4tv2 atvpch2.brk

rem Mix the two transposed versions (spread at bottom)
submix mix aftv1-2a.mix arfbdtbl50x4tv1-2mixa

rem Mix the two transposed versions, with 2nd & 3rd later
submix mix aftv1-2b.mix arfbdtbl50x4tv1-2mixb

rem Dovetail end of the final file
envel dovetail 1 arfbdtbl50x4tv1-2mixb arfbdtbl50x4tv1-2mixbdt 0.05 1.0 0 0

echo off

prompt $P$G

