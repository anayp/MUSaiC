# CDP DAW Workflow (Antigravity)

This repo now includes a JSON-driven sequencer and TUI for composing with CDP.

## Quick Start
Run the interactive loader:
```powershell
.\cdp-wrapper.ps1
```
Or run the sequencer directly:
```powershell
.\cdp-sequencer.ps1 -ScorePath examples\beat_score.json -Play
```
CLI Options:
- `-OutWav <path>`: Override output filename (default: `output/<ProjectName>-master.wav`).
- `-OutMp3 <path>`: Create an MP3 version alongside the WAV.
- `-Play`: Auto-play properly on finish.

## JSON Score Schema
Scores are defined in JSON files.
```json
{
  "project": "Song Name",
  "tempo": 120, 
  "timeUnits": "beats", // "beats" or "seconds" (default). 
  // If "beats", ALL time/dur/offset values are treated as beats and converted to seconds based on tempo.
  "tracks": [
    {
      "name": "Bass",
      "type": "synth",
      "waveform": "square", // sine, square, saw, ramp
      "amp": 0.5,
      "effects": [
          { "type": "reverb", "room_size": 2.0, "mix": 0.5 },
          { "type": "pitch", "semitones": -12 }
      ],
      "events": [
        { "time": 0.0, "dur": 1.0, "pitch": 60 }, // pitch in MIDI notes
        { "time": 1.0, "dur": 0.5, "pitch": 62 }
      ]
    },
    {
      "name": "Drums",
      "type": "sample",
      "source": "examples/kick.wav", 
      "amp": 1.0,
      "events": [
        { 
            "time": 0.0, "dur": 0.25, 
            "loop": true, "loopCount": 4 
        },
        { "time": 2.0, "dur": 0.5, "offset": 0.2 }
      ]
    }
  ]
}
```

## 5. Helper Tools
### Analysis (`cdp-analyze.ps1`)
```powershell
.\cdp-analyze.ps1 -Mode info -InputFile "file.wav"
.\cdp-analyze.ps1 -Mode beats -InputFile "loop.wav"
```

### Transformation (`cdp-transform.ps1`)
```powershell
.\cdp-transform.ps1 -Mode tempo -In kick.wav -Out slow.wav -Amount 80
.\cdp-transform.ps1 -Mode pitch -In kick.wav -Out high.wav -Amount 2
```

## Scripts
- **cdp-sequencer.ps1**: Core engine. Parses JSON, renders synth notes via `synth.exe`, trims samples via `ffmpeg`, applies effects (reverb/pitch), and mixes everything.
- **cdp-wrapper.ps1**: Interactive menu to browse `examples/*.json` and render/play them.

## Requirements
- CDP `synth.exe`, `reverb.exe`, `modify.exe` in local `CDPR8\_cdp\_cdprogs`.
- `ffmpeg` in PATH.
