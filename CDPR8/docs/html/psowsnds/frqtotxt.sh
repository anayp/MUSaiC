#!/bin/bash
echo frqtotxt.sh - shell script to prepare pitch-brkpnt-data file for
echo                use with a FOF-source file: lengths must match.
if [ $# -ne 2 ]
    then
        echo usage: frqtotxt insndfile outtextfile
        exit 1
fi
echo
echo pvoc anal 1 $1 infile.ana
pvoc anal 1 $1 infile.ana
echo repitch getpitch 1 infile.ana infilepchdummy.aiff infile.frq
repitch getpitch 1 infile.ana infilepchdummy.aiff infile.frq
echo ptobrk withzeros infile.frq $2 20
ptobrk withzeros infile.frq $2 20
echo Delete \(temporary\) files no longer needed:
echo rm infile.ana
rm infile.ana
echo rm infilepchdummy.aiff
rm infilepchdummy.aiff
echo rm infile.frq
rm infile.frq
