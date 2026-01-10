;fm1.sc

f1  0  4096  10  1

i1   0     4    10000   440      5            0
i1   5     4    10000   440      5            3
i1  10     4    10000   440      5            6
i1  15     4    10000   440      5           10
i1  20     4    10000   440      5           15
;now hold vibrato depth steady and increase vibrato rate
;ins strt  dur  amp(p4) freq(p5) vib.frq(p6) vib.amp(p7)
i1   25     4    10000   440        2          4
i1   30     4    10000   440        5          4
i1   35     4    10000   440        7          4
i1   40     4    10000   440       12          4
i1   45     4    10000   440       20          4
i1   50     4    10000   440      100          4
;now we can seriously increase the modulation depth
;ins strt  dur  amp(p4) freq(p5) vib.frq(p6) vib.amp(p7)
i1   55     4    10000   440      100            10
i1   60     4    10000   440      100            50
i1   65     4    10000   440      100           100
i1   70     4    10000   440      100           500
i1   75     4    10000   440      100          1000
i1   80     4    10000   440      100          5000
;finally, we'll change the modulation frequency slightly
;ins strt  dur  amp(p4) freq(p5) vib.frq(p6) vib.amp(p7)
i1   85     4    10000   440      100           500
i1   90     4    10000   440      105           500
i1   95     4    10000   440      110           500
i1  100     4    10000   440      120           500
e
