Note Data Files for TEXTURE DECORATE (plus PREDECOR and POSTDECOR)
=====================================
In DECORATE, each pitch on a notelist, or 'line', is decorated by a group of notes.
The notelist 'line' is a timed motif, defined in NOTEDATA.
As in GROUPS / TGROUPS:
• The no. of events in each group is set by groupsize: GPSIZE LOW and GPSIZE HIGH.
• Timing of events within the group is set by GPPACK_LOW and GPPACK_HIGH. 
• Note durations are set by MIN_DUR and MAX_DUR. 
• Loudness is chosen randomly, between MIN_GAIN and MAX_GAIN.

notedata.txt (Mode 5: 'None')
------------ 
•An input MIDI pitch (60) -- i.e. original pitch, followed by
• substructure 'line' of notes:

#4	- no. of notes
0.0 1 60 0 0	C4
0.5 1 64 0 0	E4
1.0 1 63 0 0	D#4
1.5 1 66 0 0	F#4

Times (1st field) are the decoration start times: equally spaced here, but need not be.
(Note that amp and duration fields are not used.)

Pitches are chosen from within GPRANGE (set by GPRANGE_LOW and GPRANGE_HIGH) - the pitch range outwards from the central pitch (in semitones?).


notedata-chord.txt (Modes 1-4: Harmonic set/field)
------------------
Input MIDI pitch, followed by substructure 'line' (as above) followed by a decoration pitch set.
The decorations, placed on the notes of the substructure 'line', are randomly selected from this note list:

#3	- No. of notes 
0.0 1 60 0 0	C4
0.0 1 64 0 0	E4
0.0 1 67 0 0	G4

Fields are:
Time 	 not used here, so 0
Instr# 	 set to 1 but not used 
Pitch 	 MIDI
Amp 	 not used here, so 0
Durn 	 not used here, so 0

Harmonic Set: 	actual pitches are used for the decoration, chosen randomly
Harmonic Field: pitches chosen randomly from set, but can be in any 8ve.
In Modes 1-4, GPRANGE defines the number of notes in the harmonic field/set used for the decoration pitches. 

* * * * * *

NOTE: It seems that where the notes of the 'line' fall outside those of the Hmc Set, they are not decorated; only those notes that are within the range of the set are decorated.

For example, change the 'line' above to pitches 72, 70, 68, 66: only the last note is decorated in Mode 3 (harmonic set). However, all notes are decorated in Mode 1 (harmonic field), because the set is now duplicated across all (?) octaves.  
Increase the group size and group range to 6, with Mode=1 (harmonic field): each decoration now consists of a major-triad arpeggio of 6 notes -- see Preset: Arpeggios (devised for source gtr.wav).

DECORATE / PREDECOR / POSTDECOR
================================
The decorations are connected to the line: centred (DECORATE), before and ending on (PREDECOR), and starting precisely on (POSTDECOR), these time points.

Use the 'Choose Process' radio buttons to select the desired function.





