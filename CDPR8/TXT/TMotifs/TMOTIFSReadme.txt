Note Data Files for TEXTURE TMOTIFS/HARMONIC MOTIFS
====================================================
In TEXTURE TMOTIFS, fully defined motifs begin to play at the times specified in a rhythmic template, defined in NOTEDATA.
• SKIPTIME is the time between repetitions of the rhythmic template. 
In most Texture programs, this is a pause between the end of one group or motif and the next, but in TMOTIFS it is the time between the start of one motif and the next, irrespective of the motif's own length. (This allows for overlap between the note-groups -- see for ex. Preset TMotif2B.)
• The overall level of the motif is chosen randomly, between MIN_GAIN and MAX_GAIN. (Loudness within the motif is set by each note's Amplitude.)  

notedata.txt (Mode 5: 'None')
------------ 
• An input MIDI pitch (60) -- i.e. original pitch, followed by
• a rhythmic motif (c.f. that used in TIMED/TGROUPS):

#5	- no. of notes
0.0 1 0 0 0
1.0 1 0 0 0
1.5 1 0 0 0
2.0 1 0 0 0
2.5 1 0 0 0

Fields are:
Time 	 start-time of the motif, defining the macro-rhythm 
Instr# 	 set to 1 but not used 
Pitch 	 MIDI - here 0 as not used
Amp 	 0 as not used
Durn 	 0 as not used

• motif of notes (here, same as that used for MOTIFS and ORNATE's ornament):
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

Pitches within the motif are as defined, but the starting pitch of each motif is chosen at random from within the Pitch Range, set by MIN_PITCH and MAX_PITCH.  


notedata-chord.txt (Modes 1-4: Harmonic set/field)
-------------------
• Input MIDI pitch, followed by
• rhythmic motif (as above), followed by
• a pitch set, folowed by
• a motif (as above)

Pitch set (here, the octatonic scale, as used in TIMED / TGROUPS):

#8	 - no. of notes
0.0 1 60 0 0	C
0.0 1 61 0 0	C#
0.0 1 63 0 0	D#
0.0 1 64 0 0	E
0.0 1 66 0 0	F#
0.0 1 67 0 0	G
0.0 1 69 0 0	A
0.0 1 70 0 0	Bb

Fields are:
Time 	 not used here, so 0
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

 





