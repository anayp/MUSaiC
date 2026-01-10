;chorus.orc

sr = 22050
kr =  1470
ksmps = 15
nchnls = 1

instr 4

inote = cpspch(p5)
k1  linen  10000,  p6,  p3,  p7  ;NB commas between parameters
a1  oscil  k1,  inote * .99, 1	 ;are missing in my text
a2  oscil  k1,  inote * 1.01, 1
a3  oscil  k1,  inote, 1
a1  = (a1+a2+a3)/3		 ;'/3' to prevent ampl overflow
    out    a1
endin
