Note Data Files for TEXTURE MOTIFS /HARMONIC MOTIFS 
===================================================

notedata.txt (Mode 5: 'None')
------------ 
• An input MIDI pitch (60) -- i.e. original pitch, followed by
• motif of notes (here, same as that used for ORNATE's ornament and TMOTIFS):

#5      - no. of notes
(T  I P  A  D)  			
0.0 1 60 70 0.3	  C4
0.1 1 61 50 0.3	  C#4
0.2 1 63 50 0.3	  D#4
0.3 1 64 50 0.3	  E
0.4 1 66 70 0.6	  F#

Fields are:
Time 	 start-time of the note-event, defining the rhythm 
Instr# 	 set to 1 but not used 
Pitch 	 MIDI
Amp 	 MIDI 0-127
Durn 	 length of note: secs.

Starting pitch of each repetition is chosen at random from the pitch range set by MIN PITCH and MAX PITCH.
On repetition, the duration of the motif can be varied by using the multipliers MULT LOW and MULT HI. (If not wanted, set both to 1; for a fixed value, give both the same value.) 


notedata-chord.txt (Modes 1-4: Harmonic set/field)
-------------------
• Input MIDI pitch, followed by
• a pitch set, followed by
• motif (as above)

Pitch Set:
#4	 - no. of notes
(T  I P  A D) 
0.0 1 60 70 0
0.0 1 63 50 0
0.0 1 65 50 0
0.0 1 68 50 0

Fields are:
Time 	 not used here, so 0 (but needed for Modes 2 and 4)
Instr# 	 set to 1 but not used 
Pitch 	 MIDI
Amp 	 not used here, so 0
Durn 	 not used here, so 0

Harmonic Set: 	motif starts on a pitch chosen from the pitch set, but within the pitch range.
Harmonic Field: starting pitch is chosen from the pitch set, but can be in any 8ve within pitch range.
Pitch Range: 	set by MIN_PITCH and MAX_PITCH.

HARMONIC MOTIFS (CDP: motifsin) - Mode 1-4 only; no Mode 5
===============
All the notes of the motif are 'forced' onto the field: the motif is altered as necessary by warping/transposition/note-repetitions.

PRESETS
-------
Warning!
When running the presets, make sure that the correct number of input files have been loaded.
3A, 3B, 3C and 4 all need 2 inputs (which can be the same file).
The others must have only one input. 




 





