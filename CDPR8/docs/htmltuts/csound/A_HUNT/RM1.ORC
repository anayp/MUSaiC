sr = 22050
kr =  1470
ksmps = 15
nchnls = 1

;multiplication instrument
instr 1

a1  oscil  p6, p7, 1
a2  oscil  p4, p5, 1
    out    a1 * a2
endin

;simple oscillator for comparison
instr 2
a3  oscil  p4, p5, 1
    out    a3
endin
