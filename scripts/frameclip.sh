#!/bin/zsh
# Align the screen-video to the in-app WAV via the clapperboard, trim it off, and frame.
# Pairs with shoot.sh, which captures <scene>_video.mp4 + <scene>_audio.wav using an in-app
# clapperboard: a brief white flash + click + @PROMO anchor, all at the same instant.
#   - flash  → found in the VIDEO (negate→blackdetect)         = T_v
#   - click  → found in the AUDIO (first silencedetect onset)  = T_a
#   offset = T_v - T_a  → delay the WAV onto the video timeline; trim past the flash; frame.
# Usage: frameclip.sh <video.mp4> <audio.wav> "<caption>" <out.mp4>   (set PROMO_CONFIG for brand)
set -e
DIR="${0:A:h}"
VID="$1"; AUD="$2"; CAP="$3"; OUT="$4"

# 1. Clapperboard flash in video (white → black after negate). Robust: never let an empty
#    detection kill the script under set -e.
DET=$(ffmpeg -hide_banner -i "$VID" -vf "negate,blackdetect=d=0.06:pix_th=0.10" -f null - 2>&1 \
  | grep -oE "black_start:[0-9.]+ black_end:[0-9.]+" | head -1 || true)
TV=$(printf '%s' "$DET"  | grep -oE "black_start:[0-9.]+" | cut -d: -f2 || true)
TVE=$(printf '%s' "$DET" | grep -oE "black_end:[0-9.]+"   | cut -d: -f2 || true)
# 2. Click onset in audio (first onset).
TA=$(ffmpeg -hide_banner -i "$AUD" -af "silencedetect=noise=-30dB:d=0.03" -f null - 2>&1 \
  | grep -oE "silence_end: [0-9.]+" | head -1 | grep -oE "[0-9.]+" || true)
echo "detect: flash=$TV flash_end=$TVE click=$TA"

SKIP=0.5   # start each stream this far past its clapperboard mark (skips the ~0.35s flash/click)
if [[ -n "$TV" && -n "$TA" ]]; then
  VSS=$(python3 -c "print(round(max(0.0, $TV + $SKIP), 3))")
  ASS=$(python3 -c "print(round(max(0.0, $TA + $SKIP), 3))")
  echo "clapperboard: flash@${TV}s end@${TVE}s click@${TA}s → video from ${VSS}s, audio from ${ASS}s (aligned, clapperboard trimmed)"
else
  VSS=0; ASS=0
  echo "WARN: no clapperboard flash detected — muxing from start (A/V may be off)"
fi

# 3. Seek EACH input to its scene-start mark (video→flash, audio→click), so they land aligned;
#    then mux. Robust to any capture offset (no -itsoffset/output-ss math). -shortest clips to
#    whichever runs out (the audio scene ends first). Preserve VFR video timing.
ALIGNED="${OUT:r}_aligned.mp4"
ffmpeg -y -ss "$VSS" -i "$VID" -ss "$ASS" -i "$AUD" \
  -map 0:v -map 1:a -fps_mode:v passthrough -c:v libx264 -pix_fmt yuv420p -crf 18 \
  -c:a aac -b:a 192k -shortest "$ALIGNED" >/dev/null 2>&1

# 4. Frame into the branded device mockup (frame.sh preserves timing via -fps_mode passthrough).
PROMO_CONFIG="${PROMO_CONFIG:-$DIR/config.sh}" zsh "$DIR/frame.sh" av "$ALIGNED" "$CAP" "$OUT"
echo "framed → $OUT"
