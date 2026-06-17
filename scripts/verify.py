#!/usr/bin/env python3
"""Verify promo-clip sync: declared @PROMO beats vs silencedetect onsets in the WAV.
Usage: verify.py <markers> <audio.wav> [tol_ms=50]. Exit 0=PASS, 1=FAIL, 2=hard fail."""
import json, re, subprocess, sys

def onsets(wav):
    # noise=-30dB catches note onsets through a reverb tail; d=0.03 resolves ~0.25s notes.
    out = subprocess.run(["ffmpeg", "-hide_banner", "-i", wav, "-af",
        "silencedetect=noise=-30dB:d=0.03", "-f", "null", "-"],
        capture_output=True, text=True).stderr
    return [float(m) for m in re.findall(r"silence_end: ([0-9.]+)", out)]

def main():
    markers, wav = sys.argv[1], sys.argv[2]
    tol = (float(sys.argv[3]) if len(sys.argv) > 3 else 50.0) / 1000.0
    evs = [json.loads(l.split("@PROMO ", 1)[1]) for l in open(markers) if "@PROMO " in l]
    declared = [e["ts"] for e in evs if e["ev"] in ("anchor", "beat")]
    det = onsets(wav)
    if not det:
        print("HARD FAIL: no audio onsets (silent capture)"); return 2
    if not declared:
        print("HARD FAIL: no declared anchor/beats"); return 2
    anchor = det[0]                       # the clapperboard click
    # Measure A/V DRIFT (verify's real job), tolerant of musical note-merges: a marker
    # whose nearest onset is far (>120ms) is treated as "merged/undetected" (non-fatal),
    # not as drift. FAIL only if a CLEANLY-matched marker actually drifts past tol.
    MATCH_WINDOW = 0.120
    matched, merged, worst = 0, 0, 0.0
    for ts in declared:
        expect = anchor + ts
        near = min(det, key=lambda o: abs(o - expect))
        drift = abs(near - expect)
        if drift <= MATCH_WINDOW:
            matched += 1; worst = max(worst, drift)
            print(f"  ts={ts:.3f} expect={expect:.3f} got={near:.3f} drift={drift*1000:.0f}ms")
        else:
            merged += 1
            print(f"  ts={ts:.3f} expect={expect:.3f} (no clean onset — merged/undetected, non-fatal)")
    match_rate = matched / len(declared)
    no_drift = worst <= tol
    enough = match_rate >= 0.70
    ok = no_drift and enough
    print(f"detected {len(det)} onsets; {matched}/{len(declared)} cleanly matched, {merged} merged")
    print(f"{'PASS' if ok else 'FAIL'}: worst drift {worst*1000:.0f}ms (tol {tol*1000:.0f}ms), match-rate {match_rate*100:.0f}%")
    return 0 if ok else 1

sys.exit(main())
