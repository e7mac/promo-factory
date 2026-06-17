#!/bin/zsh
# Unattended single-scene promo capture. No BlackHole/sox/idb — audio comes from the
# app's in-engine PromoTap (WAV in the app container); markers come from stdout.
# Usage: shoot.sh <udid> <bundleId> <scene> <maxSecs> <outdir> ["KEY=VAL ..." extraLaunchEnv]
set -e
UDID="$1"; BUNDLE="$2"; SCENE="$3"; MAX="${4:-30}"; OUT="${5:-/tmp/promo}"; LENV="$6"
mkdir -p "$OUT"
MK="$OUT/$SCENE.markers"; VID="$OUT/${SCENE}_video.mp4"; AUD="$OUT/${SCENE}_audio.wav"

xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged \
  --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi 2>/dev/null || true

xcrun simctl io "$UDID" recordVideo --codec h264 --force "$VID" >/tmp/${SCENE}_v.log 2>&1 &
VP=$!
prefix=(SIMCTL_CHILD_PROMO_DEMO=1)
for kv in ${(s: :)LENV}; do prefix+=("SIMCTL_CHILD_${kv}"); done
( env $prefix xcrun simctl launch --console-pty "$UDID" "$BUNDLE" ) >"$MK" 2>&1 &
LP=$!

for i in $(seq 1 $((MAX*2))); do
  grep -q '"ev":"scene-end"' "$MK" 2>/dev/null && break
  sleep 0.5
done
sleep 0.5
kill -INT $VP 2>/dev/null || true; kill $LP 2>/dev/null || true; wait 2>/dev/null || true
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true

CT=$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)
cp "$CT/Documents/scene.wav" "$AUD"
echo "markers=$MK video=$VID audio=$AUD"
echo "--- markers ---"; cat "$MK" | grep '@PROMO' || true
