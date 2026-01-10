prompt $G
rem frqtotxt.bat - batch file to carry out the 3 steps to 
rem               make the breakpoint pitch file needed by PSOW 
echo off
if  "%1" == "" GOTO errq
if  "%2" == "" GOTO errq
echo on
copysfx %1 infile.wav
pvoc anal 1 infile.wav infile.ana
repitch getpitch 1 infile.ana infilepchdummy.wav infile.frq
ptobrk withzeros infile.frq %2 20
rem Delete files no longer needed
del infile.wav
del infile.ana
del infilepchdummy.wav
del infile.frq
goto done
:errq
echo usage: frqtotxt insndfile outtextfile
:done
prompt $P$G



