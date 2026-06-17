#!/usr/bin/env python3
"""Branded end card (1080x1920). Env:
  ICON=/path/to/AppIcon-1024.png  TITLE="App Name"  SUB="tagline"  URL="example.com"
  OUT=endcard.png  BG=#FBF8ED BG_DARK=#EEE9D7 INK=#1A1A1A ACCENT=#D97756
"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter
def hexc(k,d):
    s=os.environ.get(k,d).lstrip("#"); return tuple(int(s[i:i+2],16) for i in (0,2,4))
CW,CH=1080,1920
CREAM=hexc("BG","FBF8ED"); DARK=hexc("BG_DARK","EEE9D7"); INK=hexc("INK","1A1A1A"); ACCENT=hexc("ACCENT","D97756")
SUBINK=hexc("SUB_INK","1A1A1A")  # set to a light hex for dark backgrounds
ICON=os.environ.get("ICON",""); TITLE=os.environ.get("TITLE","App"); SUB=os.environ.get("SUB",""); URL=os.environ.get("URL","")
OUT=os.environ.get("OUT","endcard.png")
GEO_BOLD="/System/Library/Fonts/Supplemental/Georgia Bold.ttf"; GEO="/System/Library/Fonts/Supplemental/Georgia.ttf"
bg=Image.new("RGB",(CW,CH),CREAM)
vig=Image.new("L",(CW,CH),0); ImageDraw.Draw(vig).ellipse([-CW*0.3,-CH*0.2,CW*1.3,CH*1.2],fill=255)
bg=Image.composite(bg,Image.new("RGB",(CW,CH),DARK),vig.filter(ImageFilter.GaussianBlur(CW*0.25))).convert("RGBA")
iy=int(CH*0.30)
if ICON and os.path.exists(ICON):
    S=300; icon=Image.open(ICON).convert("RGBA").resize((S,S)); r=66
    m=Image.new("L",(S,S),0); ImageDraw.Draw(m).rounded_rectangle([0,0,S-1,S-1],radius=r,fill=255); icon.putalpha(m)
    ix=(CW-S)//2
    sh=Image.new("RGBA",(CW,CH),(0,0,0,0)); ImageDraw.Draw(sh).rounded_rectangle([ix,iy+14,ix+S,iy+S+14],radius=r,fill=(26,26,26,70))
    bg=Image.alpha_composite(bg,sh.filter(ImageFilter.GaussianBlur(28))); bg.alpha_composite(icon,(ix,iy)); ty=iy+S+60
else:
    ty=int(CH*0.40)
d=ImageDraw.Draw(bg)
tf=ImageFont.truetype(GEO_BOLD,76); d.text(((CW-d.textlength(TITLE,font=tf))//2,ty),TITLE,font=tf,fill=INK)
if SUB:
    sf=ImageFont.truetype(GEO,38); d.text(((CW-d.textlength(SUB,font=sf))//2,ty+105),SUB,font=sf,fill=SUBINK)
if URL:
    uf=ImageFont.truetype(GEO,40); d.text(((CW-d.textlength(URL,font=uf))//2,ty+195),URL,font=uf,fill=ACCENT)
bg.convert("RGB").save(OUT); print("saved",OUT)
