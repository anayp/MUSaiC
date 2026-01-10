;toot3.orc

sr = 22050
kr =  1470
ksmps = 15
nchnls = 1

instr 3

k1  linen  p4, p6, p3, p7  ;NB I left out the commas in the text
a1  oscil  k1, p5, 1
    out    a1
endin
