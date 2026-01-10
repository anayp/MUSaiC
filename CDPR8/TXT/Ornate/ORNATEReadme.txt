Note Data Files for TEXTURE ORNATE  (plus PREORNATE and POSTORNATE)
===================================
In ORNATE, a fully defined motif or 'ornament' decorates each pitch on a notelist, or 'line' (the equivalent of a melodic figure being repeated in sequence, on a succession of pitches).
In ORNATE, the 'line' is itself a timed motif, defined in NOTEDATA.
Repetitions of the 'line' motif are separated by a pause of SKIPTIME seconds.

notedata.txt (Mode 5: 'None')
------------ 
• An input MIDI pitch (60) -- i.e. original pitch, followed by
• substructure 'line' of notes (here, same line as used for DECORATE):

#4	- no. of notes
0.0 1 60 0 0	C4
0.5 1 64 0 0	E4
1.0 1 63 0 0	D#4
1.5 1 66 0 0	F#4

Times (1st field) are the decoration start times: equally spaced here, but need not be.

• This is followed by the 'ornament', a motif which is placed on the 'line':

#5      - no. of notes
(T  I P  A  D)  			
0.0 1 60 70 0.3	  C4
0.1 1 61 50 0.3	  C#4
0.2 1 63 50 0.3	  D#4
0.3 1 64 50 0.3	  E
0.4 1 66 70 0.6	  F#

Fields are:
Time 	 relative to the start-time of the line note
Instr# 	 set to 1 but not used 
Pitch 	 MIDI
Amp 	 MIDI 0-127
Durn 	 secs.

Pitches are chosen by the notes of the ornate motif, on those of the line.
(ORNATE has no Pitch Range - MIN_PITCH or MAX_PITCH.) 


notedata-chord.txt (Modes 1-4: Harmonic set/field)
-------------------
• Input MIDI pitch, followed by
• substructure 'line' (as above), followed by 
• a pitch set, followed by 
• the ornament (as above). 

Only pitches from the pitch set are used:

#8	 - no. of notes
(T  I P  A D) 
0.0 1 60 0 0      C
0.0 1 61 0 0	  C#
0.0 1 63 0 0	  D#
0.0 1 64 0 0      E
0.0 1 66 0 0	  F#
0.0 1 67 0 0      G
0.0 1 69 0 0      A
0.0 1 70 0 0	  Bb

Fields are:
Time 	 not used here, so 0
Instr# 	 set to 1 but not used 
Pitch 	 MIDI
Amp 	 not used here, so 0
Durn 	 not used here, so 0

Harmonic Set: 	pitches are chosen from the pitch set
Harmonic Field: pitches are chosen from the pitch set, but can be in any 8ve.

This pitch set here is an octatonic scale , chosen to match the notes of the line and the ornament, but no matching is required: any pitches could be used for each of the note lists. 

NOTE: Although Mode 5 (no harmonic set/field) does define the pitch content fully, it may use the full chromatic scale (or even microtones); the addition of a pitch set in Modes 1-4 restricts the pitch content to the pitches of the set/field.


ORNATE / PREORNATE / POSTORNATE
==================================
The ornanaments are connected to the line: centred (ORNATE), before and ending on (PREORNATE), and starting precisely on (POSTORNATE), these time points. [...not verified R.F.]

Use the 'Choose Process' radio buttons to select the desired function.





