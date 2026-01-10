Note Data Files for TEXTURE GROUPS (same as SIMPLE)
====================================================
GROUPS plays groups of 'notes' at time-intervals set by PACKING rate, as varied by SCATTER.
The groups are separated by SKIPTIME.
The no. of events in each group is set by groupsize: GPSIZE LOW and GPSIZE HIGH.
Timing of events within the group is set by GPPACK_LOW and GPPACK_HIGH. 
Note durations are set by MIN_DUR and MAX_DUR. 
Loudness is chosen randomly, between MIN_GAIN and MAX_GAIN.


notedata.txt (Mode 5: 'None')
------------ 
An input MIDI pitch (60) -- i.e. original pitch

For two inputs, put two of these, e.g. 60 60
If first sound a semitone lower than second, put 59 60.

Pitches are chosen at random from within the Pitch Range (set by MIN_PITCH and MAX_PITCH).


notedata-chord.txt (Modes 1-4: Harmonic set/field)
------------------
Input MIDI pitch, followed by a pitch set:
#4	- No. of notes
0 1 60 0 0	C4 (middle C)	
0 1 62 0 0	D4
0 1 65 0 0	F4
0 1 67 0 0	G4

Fields are:
Time 	 not used here, so 0
Instr# 	 not used here
Pitch 	 MIDI
Amp 	 not used here, so 0
Durn 	 not used here, so 0

Harmonic Set: 	pitches are chosen at random from the pitch set, but within the pitch range
Harmonic Field: pitches are chosen from the pitch set, but can be in any 8ve within pitch range.
Pitch Range: 	set by MIN_PITCH and MAX_PITCH 


