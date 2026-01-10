;fm1.orc

sr = 22050
kr =  1470
ksmps = 15
nchnls = 1

instr 1

avib oscil  p7, p6, 1
aout oscil  p4, p5 + avib, 1
     out    aout
endin
