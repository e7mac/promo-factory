#!/usr/bin/env python3
"""Brand-framed device mockup background + rounded-screen mask for compositing
an iOS screen recording with ffmpeg.

Usage:
  frame.py <canvasW> <canvasH> <vidW> <vidH> <caption> <bg_out> <mask_out>
Brand colors via env (hex), defaults = Real Sight Reader cream/clay:
  BG=#FBF8ED  BG_DARK=#EEE9D7  INK=#1A1A1A  SHELL=#FFFFFF
Optional: CAPTION_FONT=/path/to.ttf (default Georgia Bold)
Prints: OVERLAY_X OVERLAY_Y SCREEN_W SCREEN_H  (feed to ffmpeg scale/overlay)
"""
import sys, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def hexc(s, d):
    s = os.environ.get(s, d).lstrip("#")
    return tuple(int(s[i:i+2], 16) for i in (0, 2, 4))

CW, CH, VW, VH = (int(sys.argv[i]) for i in (1, 2, 3, 4))
CAPTION, BG_OUT, MASK_OUT = sys.argv[5], sys.argv[6], sys.argv[7]
CREAM = hexc("BG", "FBF8ED"); CREAM_DARK = hexc("BG_DARK", "EEE9D7")
INK = hexc("INK", "1A1A1A"); SHELL = hexc("SHELL", "FFFFFF")
FONT = os.environ.get("CAPTION_FONT", "/System/Library/Fonts/Supplemental/Georgia Bold.ttf")

vid_aspect = VW / VH
portrait = CH >= CW
cap_h = int(CH * (0.20 if portrait else 0.0))
margin = int(CH * 0.045)
SH = min(CH - cap_h - margin, int(CW * (0.62 if portrait else 0.42) / vid_aspect))
SW = int(SH * vid_aspect)
OX = (CW - SW) // 2
OY = cap_h + (CH - cap_h - SH) // 2
r_screen = int(SW * 0.085)
pad = max(10, int(SW * 0.022))
r_bezel = r_screen + pad

bg = Image.new("RGB", (CW, CH), CREAM)
vig = Image.new("L", (CW, CH), 0)
ImageDraw.Draw(vig).ellipse([-CW*0.3, -CH*0.2, CW*1.3, CH*1.2], fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(CW*0.25))
bg = Image.composite(bg, Image.new("RGB", (CW, CH), CREAM_DARK), vig).convert("RGBA")

shadow = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
ImageDraw.Draw(shadow).rounded_rectangle(
    [OX-pad, OY-pad+int(SH*0.012), OX+SW+pad, OY+SH+pad+int(SH*0.012)],
    radius=r_bezel, fill=(26, 26, 26, 60))
bg = Image.alpha_composite(bg, shadow.filter(ImageFilter.GaussianBlur(pad*1.6)))

d = ImageDraw.Draw(bg)
d.rounded_rectangle([OX-pad, OY-pad, OX+SW+pad, OY+SH+pad], radius=r_bezel, fill=SHELL+(255,))

if cap_h > 0 and CAPTION:
    fs = int(CW * 0.062); font = ImageFont.truetype(FONT, fs)
    words, lines, cur = CAPTION.split(), [], ""
    maxw = int(CW * 0.86)
    for w in words:
        t = (cur + " " + w).strip()
        if d.textlength(t, font=font) <= maxw: cur = t
        else: lines.append(cur); cur = w
    if cur: lines.append(cur)
    lh = int(fs * 1.18); ty = (cap_h - lh*len(lines))//2 + int(CH*0.02)
    for ln in lines:
        d.text(((CW - d.textlength(ln, font=font))//2, ty), ln, font=font, fill=INK)
        ty += lh

bg.convert("RGB").save(BG_OUT)
mask = Image.new("L", (SW, SH), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, SW-1, SH-1], radius=r_screen, fill=255)
mask.save(MASK_OUT)
print(f"{OX} {OY} {SW} {SH}")
