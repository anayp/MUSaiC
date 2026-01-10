;buzz1.orc

sr = 22050
kr =  1470
ksmps = 15
nchnls = 1

instr 1
k1  linen  p4, p6, p3, p7
a1  buzz   k1, p5, p8, 1
    out    a1
endin
