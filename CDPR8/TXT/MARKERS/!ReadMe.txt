The three files are examples of Markers (labels) exported from:

Audacity:     labels.txt
Wavesurfer:   labels.lab
Viewsf (CDP): Marks.dat

Soundshaper can import any of these to its Markers list and if they are saved to the TEMP.OUTFILES folder, they can be grabbed from there by clicking the GET button.

The pecking order for GET is:
 1 if Option 'Audacity labels' is checked, and labels.txt exists, grab from there.
 2 if Option unchecked, and if labels.lab exists, grab from there.
 3 if Option unchecked and labels.lab does not exist, grab from Marks.dat if it exists. 

An alternative way of interacting with an external audio editor is to save a marked chunk as a separate file from the editor, import this into Soundshaper and process it , then import it back into the editor to replace the marked section. This works well with Waveosaur (which is not able yet to export markers). 

R.F.