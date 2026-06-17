#!/bin/zsh
# Composite a clip into the branded device frame. TWO modes:
#   frame.sh av  <stitched.mp4> "<caption>" <out.mp4>     # keep the clip's OWN synced audio
#   frame.sh bed <video.mp4>    "<caption>" <out.mp4> <bed.wav>  # lay a music bed (silent clips)
#
# KEY: video timeline is preserved with -fps_mode passthrough (no re-timing). simctl recordVideo is
# VFR with big PTS gaps; CFR-converting it (fps filter OR -r flag) shifts where events land and
# desyncs audio even when total duration matches. Scale/overlay/caption do NOT touch PTS, so the
# framed clip is timing-identical to the stitched master you approved. Verify: framed `silencedetect`
# onsets must equal the source's, and durations must match.
set -e
DIR="${0:A:h}"; source "${PROMO_CONFIG:-$DIR/config.sh}"
MODE="$1"; SRC="$2"; CAP="$3"; OUT="$4"; BED="$5"
W=$ROOT/work
VW=$(ffprobe -v error -select_streams v -show_entries stream=width  -of csv=p=0 "$SRC")
VH=$(ffprobe -v error -select_streams v -show_entries stream=height -of csv=p=0 "$SRC")
GEO=$(python3 "$DIR/frame.py" $CANVAS_W $CANVAS_H $VW $VH "$CAP" "$W/_bg.png" "$W/_mask.png")
read -r OX OY SW SH <<<"$GEO"

if [[ "$MODE" == "av" ]]; then
  DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$SRC")
  FO=$(python3 -c "print(max(0,$DUR-1.0))")
  ffmpeg -v error -i "$SRC" -i "$W/_bg.png" -i "$W/_mask.png" \
    -filter_complex "[0:v]scale=${SW}:${SH},format=rgba[v];[v][2:v]alphamerge[rv];[1:v][rv]overlay=${OX}:${OY}[out];[0:a]afade=t=in:st=0:d=0.3,afade=t=out:st=${FO}:d=1.0[a]" \
    -map "[out]" -map "[a]" -fps_mode:v passthrough -c:v libx264 -pix_fmt yuv420p \
    -c:a aac -b:a 256k -ar 48000 -movflags +faststart -y "$OUT"
else
  # No captured-audio sync here, so CFR is safe — and REQUIRED: a static screen recording may
  # contain only 1-2 real frames over its window, so passthrough would end at the last frame.
  # fps=30 + tpad clone-holds the last frame, then -t caps to the source's container duration.
  DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$SRC")
  FO=$(python3 -c "print(max(0,$DUR-1.3))")
  ffmpeg -v error -i "$SRC" -i "$W/_bg.png" -i "$W/_mask.png" \
    -filter_complex "[0:v]fps=30,tpad=stop_mode=clone:stop_duration=${DUR},scale=${SW}:${SH},format=rgba[v];[v][2:v]alphamerge[rv];[1:v][rv]overlay=${OX}:${OY}[out]" \
    -map "[out]" -an -t "$DUR" -c:v libx264 -pix_fmt yuv420p -movflags +faststart -y "$W/_fr.mp4"
  ffmpeg -v error -i "$W/_fr.mp4" -i "$BED" \
    -filter_complex "[1:a]atrim=0:${DUR},afade=t=in:st=0:d=0.8,afade=t=out:st=${FO}:d=1.3,volume=2.2,aresample=48000[a]" \
    -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 256k -ar 48000 -shortest -movflags +faststart -y "$OUT"
fi
echo "framed: $OUT"
