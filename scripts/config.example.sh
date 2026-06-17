# Per-app promo config. Copy to config.sh next to it and edit. All scripts source this.
# ---------------------------------------------------------------------------------
UDID="REPLACE-WITH-BOOTED-SIM-UDID"     # xcrun simctl list devices | grep Booted
BUNDLE_ID="com.you.yourapp"             # xcrun simctl listapps $UDID | grep -i Bundle

# Audio rig (see AUDIO-GOTCHAS.md). Install: brew install blackhole-2ch switchaudio-osx sox
APP_AUDIO_DEVICE="BlackHole 2ch"        # virtual loopback the Simulator outputs to
SPEAKERS="MacBook Pro Speakers"         # restore target after capture
MIC="MacBook Pro Microphone"
GAIN_DB=20                              # boost for quiet sim capture; keep stitched max < 0 dB

# Brand — frame.py / endcard.py read these (defaults = Real Sight Reader cream/clay)
export BG="#FBF8ED" BG_DARK="#EEE9D7" INK="#1A1A1A" SHELL="#FFFFFF"
export ACCENT="#D97756"
export CAPTION_FONT="/System/Library/Fonts/Supplemental/Georgia Bold.ttf"

# Layout
ROOT="$HOME/Downloads/YourApp-Promo"    # work root; raw/ and framed/ live under it
CANVAS_W=1080; CANVAS_H=1920            # 9:16 social. 1920x1080 / 1080x1080 for other dests

# End card
EC_ICON="/path/to/AppIcon-1024.png"
EC_TITLE="Your App"; EC_SUB="One-line value prop."; EC_URL="yourapp.com"

mkdir -p "$ROOT/raw" "$ROOT/framed" "$ROOT/work"
