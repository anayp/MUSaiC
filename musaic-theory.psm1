
# musaic-theory.psm1
# Shared music theory logic for MUSaiC (CDP Analysis v2)

# --- Constants ---

# Krumhansl-Schmuckler Profiles
$ProfMaj = @(6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88)
$ProfMin = @(6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17)

# Note Names
$PcNames = @("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B")

# Chord Templates (Intervals from Root)
$ChordTemplates = @{
    "Maj"   = @(0, 4, 7)
    "Min"   = @(0, 3, 7)
    "Dim"   = @(0, 3, 6)
    "Aug"   = @(0, 4, 8)
    "Sus2"  = @(0, 2, 7)
    "Sus4"  = @(0, 5, 7)
    "Maj7"  = @(0, 4, 7, 11)
    "Dom7"  = @(0, 4, 7, 10)
    "Min7"  = @(0, 3, 7, 10)
    "HDim7" = @(0, 3, 6, 10)
    "Dim7"  = @(0, 3, 6, 9)
}

# --- Functions ---

function Get-KeyEstimates {
    <#
    .SYNOPSIS
        Estimates key from a pitch class histogram (array of 12 doubles).
    .OUTPUTS
        Array of PSCustomObjects @{ Root=int; Type=string; Score=double }
    #>
    param(
        [double[]]$Hist
    )

    if ($Hist.Count -ne 12) { return @() }

    $candidates = @()
    for ($root = 0; $root -lt 12; $root++) {
        # Check Major
        $sMaj = 0
        for ($i = 0; $i -lt 12; $i++) { $sMaj += $Hist[($i + $root) % 12] * $script:ProfMaj[$i] }
        $candidates += [PSCustomObject]@{ Root = $root; Type = "Major"; Score = $sMaj }

        # Check Minor
        $sMin = 0
        for ($i = 0; $i -lt 12; $i++) { $sMin += $Hist[($i + $root) % 12] * $script:ProfMin[$i] }
        $candidates += [PSCustomObject]@{ Root = $root; Type = "Minor"; Score = $sMin }
    }

    return ($candidates | Sort-Object Score -Descending)
}

function Get-BestChord {
    <#
    .SYNOPSIS
        Finds the best matching chord for a given pitch class histogram.
    .OUTPUTS
        PSCustomObject @{ Root=int; Quality=string; Score=double } or $null
    #>
    param(
        [double[]]$Hist
    )

    $bestChord = $null
    $bestScore = -9999

    foreach ($cRoot in 0..11) {
        foreach ($tmplKey in $script:ChordTemplates.Keys) {
            $ivs = $script:ChordTemplates[$tmplKey]
            
            # Helper set for intervals
            $cSet = @{}
            foreach ($x in $ivs) { $cSet[($cRoot + $x) % 12] = $true }

            $score = 0
            for ($p = 0; $p -lt 12; $p++) {
                if ($cSet.ContainsKey($p)) {
                    $score += $Hist[$p]
                }
                else {
                    # Penalize non-chord tones
                    $score -= 0.5 * $Hist[$p]
                }
            }

            if ($score -gt $bestScore) {
                $bestScore = $score
                $bestChord = @{ Root = $cRoot; Quality = $tmplKey; Score = $score }
            }
        }
    }

    if ($bestChord) {
        return [PSCustomObject]$bestChord
    }
    return $null
}

function Get-NoteName {
    param([int]$Pc)
    return $script:PcNames[$Pc % 12]
}

function Get-RomanNumeral {
    param(
        [int]$ChordRoot,
        [string]$ChordQuality,
        [int]$KeyRoot,
        [string]$KeyType
    )
    
    $deg = ($ChordRoot - $KeyRoot + 12) % 12
    
    # Base Roman numerals for Major/Minor scale degrees
    $romanBase = if ($KeyType -eq "Major") {
        @("I", "bII", "ii", "bIII", "iii", "IV", "bV", "V", "bVI", "vi", "bVII", "vii")
    }
    else {
        @("i", "bII", "ii", "III", "iii", "iv", "bV", "v", "bVI", "VI", "bVII", "VII")
    }

    $rom = $romanBase[$deg]

    # Adjust case based on chord quality
    if ($ChordQuality -match "Min" -or $ChordQuality -match "Dim") {
        $rom = $rom.ToLower()
    }
    else {
        # Force upper for Major, Aug, Dom7, etc.
        # But wait, 'vi' is already lowercase in major. 
        # If we have a Major VI in a major key (borrowed), it should be VI, not vi.
        # So we should force case based on CHORD quality, not just scale degree default.
        $rom = $rom.ToUpper()
    }
    
    # Re-lower if min/dim
    if ($ChordQuality -match "Min" -or $ChordQuality -match "Dim") {
        $rom = $rom.ToLower()
    }

    return $rom
}

Export-ModuleMember -Function Get-KeyEstimates, Get-BestChord, Get-NoteName, Get-RomanNumeral
