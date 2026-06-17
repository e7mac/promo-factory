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

# 1. Clapperboard flash in video (white → black after negate).
read TV TVE < <(ffmpeg -hide_banner -i "$VID" -vf "negate,blackdetect=d=0.08:pix_th=0.10" -f null - 2>&1 \
  | grep -oE "black_start:[0-9.]+ black_end:[0-9.]+" | head -1 | sed -E 's/black_start:([0-9.]+) black_end:([0-9.]+)/\1 \2/')
# 2. Click onset in audio (first onset).
TA=$(ffmpeg -hide_banner -i "$AUD" -af "silencedetect=noise=-30dB:d=0.03" -f null - 2>&1 \
  | grep -oE "silence_end: [0-9.]+" | head -1 | grep -oE "[0-9.]+")
if [[ -z "$TV" || -z "$TA" ]]; then echo "ERROR: clapperboard not found (flash=$TV click=$TA)"; exit 1; fi

OFFSET=$(python3 -c "print(round($TV - $TA, 3))")
TRIM=$(python3 -c "print(round($TVE + 0.08, 3))")   # start just after the flash ends
echo "clapperboard: flash@${TV}s click@${TA}s → audio offset ${OFFSET}s, trim @${TRIM}s"

# 3. Delay the WAV onto the video timeline, trim off the clapperboard. Preserve VFR video timing.
ALIGNED="${OUT:r}_aligned.mp4"
ffmpeg -y -i "$VID" -itsoffset "$OFFSET" -i "$AUD" -ss "$TRIM" \
  -map 0:v -map 1:a -fps_mode:v passthrough -c:v libx264 -pix_fmt yuv420p -crf 18 \
  -c:a aac -b:a 192k -shortest "$ALIGNED" >/dev/null 2>&1

# 4. Frame into the branded device mockup (frame.sh preserves timing via -fps_mode passthrough).
PROMO_CONFIG="${PROMO_CONFIG:-$DIR/config.sh}" zsh "$DIR/frame.sh" av "$ALIGNED" "$CAP" "$OUT"
echo "framed → $OUT"
