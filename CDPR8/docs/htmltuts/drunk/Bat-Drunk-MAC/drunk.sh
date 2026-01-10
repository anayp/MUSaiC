#!/bin/bash

echo 

echo drunk.bat - batch file to create 7 different results with DRUNK
echo 

echo INFILE:  COUNT.aiff  44100, MONO, 8.066 sec
echo Generic infile:
echo copysfx count infile
copysfx count infile
echo 

echo EXAMPLE 1 - MOVE
echo 

echo            INFILE OUTFILE  LENGTH LOCUS       AMBITUS STEP CLOCK
echo extend drunk 1 infile cd1 25     locus1.brk  .5      .1   .2
extend drunk 1 infile cd1 25     locus1.brk  .5      .1   .2
echo 

echo 

echo EXAMPLE 2 - WIDEN \& SPEED UP
echo extend drunk 1 infile cd2 25 locus1.brk ambitus1.brk step1.brk clock1.brk
extend drunk 1 infile cd2 25 locus1.brk ambitus1.brk step1.brk clock1.brk
echo 

echo 

echo EXAMPLE 3 - INCREASED SCATTER
echo extend drunk 1 infile cd3 25 locus1.brk 1.32 step2.brk clock2.brk
extend drunk 1 infile cd3 25 locus1.brk 1.32 step2.brk clock2.brk
echo 

echo 

echo EXAMPLE 4 - HOVER
echo extend drunk 1 infile cd4 25 locus2.brk ambitus3.brk step3.brk clock3.brk
extend drunk 1 infile cd4 25 locus2.brk ambitus3.brk step3.brk clock3.brk
echo 

echo 

echo EXAMPLE 5 - EXPAND
echo extend drunk 1 infile cd5 25 4 ambitus4.brk step4.brk clock4.brk
extend drunk 1 infile cd5 25 4 ambitus4.brk step4.brk clock4.brk
echo 

echo 

echo EXAMPLE 6 - CONTRACT
echo extend drunk 1 infile cd6 25 4 ambitus5.brk step5.brk clock5.brk
extend drunk 1 infile cd6 25 4 ambitus5.brk step5.brk clock5.brk
echo 

echo EXAMPLE 7 - SWING
echo extend drunk 1 infile cd7 25 locus3.brk 0.25 0.1 0.08
extend drunk 1 infile cd7 25 locus3.brk 0.25 0.1 0.08
echo modify space 1 cd7 cd7pan panex7.brk
modify space 1 cd7 cd7pan panex7.brk
echo 


