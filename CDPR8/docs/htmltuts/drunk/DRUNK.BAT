prompt $G

echo on

rem drunk.bat - batch file to create 7 different results with DRUNK

rem INFILE:  COUNT.WAV  44100, MONO, 8.066 sec
rem Generic infile:
copysfx count infile

rem EXAMPLE 1 - MOVE

rem            INFILE OUTFILE  LENGTH LOCUS       AMBITUS STEP CLOCK
extend drunk 1 infile cd1 25     locus1.brk  .5      .1   .2


rem EXAMPLE 2 - WIDEN & SPEED UP
extend drunk 1 infile cd2 25 locus1.brk ambitus1.brk step1.brk clock1.brk


rem EXAMPLE 3 - INCREASED SCATTER
extend drunk 1 infile cd3 25 locus1.brk 1.32 step2.brk clock2.brk


rem EXAMPLE 4 - HOVER
extend drunk 1 infile cd4 25 locus2.brk ambitus3.brk step3.brk clock3.brk


rem EXAMPLE 5 - EXPAND
extend drunk 1 infile cd5 25 4 ambitus4.brk step4.brk clock4.brk


rem EXAMPLE 6 - CONTRACT
extend drunk 1 infile cd6 25 4 ambitus5.brk step5.brk clock5.brk

rem EXAMPLE 7 - SWING
extend drunk 1 infile cd7 25 locus3.brk 0.25 0.1 0.08
modify space 1 cd7 cd7pan panex7.brk

echo off

prompt $P$G