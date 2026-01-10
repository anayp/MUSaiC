;osc1.orc
sr = 22050	;falcon DAC sr = 20770 
kr =  1470	;	    kr =   670
ksmps = 15	;	 ksmps =    31
nchnls = 1

instr 1
a1  oscil p4, p5, 1
    out	  a1
endin  

