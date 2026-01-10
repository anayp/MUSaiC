Note Data Files for TEXTURE TIMED-GROUPS  (same as TIMED)
=========================================
TGROUPS plays groups of 'notes'; the onset of each group is timed by a rhythmic motif defined in NOTEDATA. The groups are separated by a pause of length SKIPTIME.
The no. of events in the group is set by groupsize: GPSIZE LOW and GPSIZE HIGH*.
Timing of events within the group is set by GPPACK_LOW and GPPACK_HIGH.
Note durations are set by MIN_DUR and MAX_DUR. 
Loudness is chosen randomly, between MIN_GAIN and MAX_GAIN.

*NOTE: if GPSIZE is set to 1, the output will be the same as TIMED. In TIMED, individual 'notes' are attached to the rhythm. In TGROUPS, it is groups of notes that are attached to the rhythm. 

notedata.txt (Mode 5: 'None')
------------ 
• An input MIDI pitch (60) -- i.e. original pitch, followed by
• a rhythmic motif (as used in TIMED):

#5	- no. of notes
0.00 1 0 0 0
0.15 1 0 0 0
0.25 1 0 0 0
1.00 1 0 0 0
1.50 1 0 0 0

Fields are:
Time 	 start-time of the note-event, defining the rhythm 
Instr# 	 set to 1 but not used 
Pitch 	 MIDI - here 0 as not used
Amp 	 0 as not used
Durn 	 0 as not used (set by parameters MIN_DUR and MAX_DUR)

Pitches are chosen at random from within the Pitch Range (set by MIN_PITCH and MAX_PITCH)


notedata-chord.txt (Modes 1-4: Harmonic set/field)
-------------------
• Input MIDI pitch, followed by
• rhythmic motif (as above), followed by
• a pitch set (here, the octatonic scale, as in TIMED):

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

Harmonic Set: 	pitches are chosen at random from the pitch set, but within the pitch range.
Harmonic Field: pitches are chosen from the pitch set, but can be in any 8ve within pitch range.
Pitch Range: 	set by MIN_PITCH and MAX_PITCH.

 





