# MUSaiC Research Notes: Analysis + Generation

## Scope
- Survey open-source tools for audio analysis (tempo, pitch, loudness, structure).
- Survey symbolic (MIDI/score) analysis toolkits.
- Identify model-based generation frameworks worth studying.
- Note integration ideas for MUSaiC.

## Audio analysis libraries (MIR)
- Essentia (C++/Python): key, onset, beat, tempo, pitch, loudness, timbre; CLI tools; good for fast offline analysis.
- aubio (C/Python): onset, pitch (YIN), tempo; lightweight for timing and pitch estimates.
- madmom (Python): strong beat/downbeat tracking using neural models; suitable for rhythm validation.
- CREPE: deep-learning pitch estimator for monophonic sources; good for melody or vocal contours.
- librosa (Python): general MIR features, beat tracking, chroma; good for prototyping.

## Symbolic (MIDI/score) analysis
- music21: key estimation, chords, scale degrees, roman numerals; parse MIDI/score to objects.
- jSymbolic: large feature set for MIDI (rhythm, pitch, texture); exports stats for comparison.
- PrettyMIDI / mido: low-level MIDI I/O and manipulation; useful for transposition, merging, and event extraction.
- Musicaiz: analysis + generation utilities, chord/key prediction, pitch-class histograms, visualization.

## Model-based generation frameworks
- Magenta: Melody RNNs, Transformers, MusicVAE, GrooVAE; Continue/Interpolate/Drumify style workflows.
- MusPy: datasets, representations, evaluation metrics; works with PyTorch/TensorFlow.
- Microsoft Muzic: PopMAG, Museformer, MusicBERT, etc; large research codebase.
- DeepBach: controllable Bach chorale harmonization; good example of constraints + generation.
- Other references: MuseGAN, MuseNet (research only), FoxDot/TidalCycles (rule-based live coding).

## Integration ideas for MUSaiC
- Use analysis libraries to extract tempo, key, loudness, and pitch features into analysis.json.
- Use symbolic toolkits to compute key/chords/cadences from score.json and validate targets.
- Use model-based or rule-based generators to propose accompaniment or variations, then commit to JSON events.
- Re-run analysis after render; compare results to target metadata and adjust.
