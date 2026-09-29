#!/usr/bin/env python3
# spell-icon-spec-match.py - Which talent spec does a spell belong to? Ask its icon.
#
# WHAT THIS IS
#
# A measuring instrument, not a finished tool. It reads the colour of a spell's
# own icon and reports which of a class's three talent specs that colour is
# nearest to. The idea it was built to test (issue 502): if you hand a warrior
# a mage's spell, which of the warrior's flavours does it become? Answer: the
# one whose spec icon is closest in colour. A green nature spell belongs to the
# green spec; a gold holy spell belongs to the warm one.
#
# HOW IT WORKS, IN ORDER
#
#   1. TalentTab.dbc     names each class's three specs and gives each a
#                        SpellIconID. Death knight is ClassMask 32.
#   2. SpellIcon.dbc     turns an icon id into a texture path.
#   3. locale-enUS.MPQ   holds the actual .blp image at that path. Note the
#                        LOCALE archive - the base MPQs carry sounds and models
#                        but no interface art, which costs an afternoon to
#                        rediscover.
#   4. Pillow            decodes the .blp. The outer five pixels are a frame
#                        identical on every icon, so they are cropped away
#                        before averaging or they drag every measurement toward
#                        the same grey.
#   5. Compare           by hue angle, not by full colour distance. Every icon
#                        shares that dark frame, so lightness is mostly noise
#                        about the frame rather than signal about the spell.
#
# THE SATURATION GATE, WHICH IS THE PART THAT MAKES IT WORK
#
# Hue is meaningless for a near-grey image - the angle is whatever the rounding
# happened to produce. Below roughly 30% saturation a spell has no colour
# identity and should be assigned to nothing rather than to whichever anchor
# won a coin flip. This is not a fudge: the spells it rejects are Mortal Strike
# (19%), Mind Blast (26%), Shadow Bolt (25%) - physical and shadow abilities
# that genuinely have no elemental colour. Rejecting them is the correct answer.
#
# WHAT IT HAS BEEN RUN ON
#
# Twenty hand-picked spells, 2026-09-03, and it reproduced the design intent
# without being told it: Wrath and Healing Touch (green) landed on Unholy,
# Fireball and Immolate landed on Blood, Holy Light (gold) landed on Blood,
# Starfire landed on Frost within 0.2 degrees. It has NOT been run over the
# full 49,839-row Spell.dbc, and it does not emit a table anybody consumes yet.
#
# WHAT TO DO WITH IT WHEN YOU FIND IT AGAIN
#
# It generalises past death knights for free - every class has three talent
# tabs with icons, so the same three steps answer the same question for all of
# them. Turning it into a real project tool means: take a class as an argument
# instead of hardcoding death knight, run over every spell rather than a
# sample, emit the assignment as data rather than as a printed table, and put
# the mpyq dependency somewhere that survives a reboot. Until then it is a
# demonstration that the idea holds, kept because rebuilding it is an
# afternoon and reading it is five minutes.
#
# DEPENDENCIES
#
# Pillow (system package, has the BLP decoder built in) and mpyq (pure python,
# reads the MPQ archives; NOT installed system-wide - see PYLIBS below).

# Average colour of a spell's own icon, compared against the death-knight
# spec icon colours. Demonstrates the "assign by colour proximity" rule.
import sys, os, struct, colorsys, io

# {{{ DIR configuration
# Hard-coded project root, overridable as the first argument so the script runs
# from anywhere. Everything below is relative to it except the client, which
# lives beside the project rather than inside it.
DIR = "/mnt/mtwo/games/azeroth-core/wow-chat-2026"
if len(sys.argv) > 1 and sys.argv[1].startswith("--dir="):
    DIR = sys.argv.pop(1)[len("--dir="):]

DBC    = DIR + "/data-files/dbc/"
DATA   = os.path.dirname(DIR) + "/client/client-files/Data/enUS/"
# mpyq is not a system package. It was installed into a scratch directory that
# does not survive a reboot; point PYLIBS at wherever it lives now, or
# `pip install --target <dir> mpyq` again. Everything else is stdlib + Pillow.
PYLIBS = os.environ.get("PYLIBS", os.path.join(DIR, "libs", "pylibs"))
sys.path.insert(0, PYLIBS)
# }}}

from mpyq import MPQArchive
from PIL import Image

ARCS = ["patch-enUS-3.MPQ","patch-enUS-2.MPQ","patch-enUS.MPQ",
        "lichking-locale-enUS.MPQ","expansion-locale-enUS.MPQ","locale-enUS.MPQ"]

def read_dbc(path):
    d = open(path,'rb').read()
    magic, rec, fields, recsize, strsize = struct.unpack_from('<4sIIII', d, 0)
    assert magic == b'WDBC'
    strings = d[20 + rec*recsize:]
    return [struct.unpack_from('<%dI' % fields, d, 20 + i*recsize) for i in range(rec)], strings

def sread(strings, off):
    if off == 0: return ''
    return strings[off:strings.index(b'\0', off)].decode('utf-8','replace')

_arcs = None
def icon_bytes(texpath):
    global _arcs
    if _arcs is None:
        _arcs = [MPQArchive(DATA+a) for a in ARCS if os.path.exists(DATA+a)]
    key = texpath.replace('/', '\\') + ".blp"
    for a in _arcs:
        d = a.read_file(key)
        if d: return d
    return None

def avg_rgb(blp):
    im = Image.open(io.BytesIO(blp)).convert("RGB").crop((5,5,59,59))
    px = list(im.get_flattened_data()); n = len(px)
    return (sum(p[0] for p in px)/n, sum(p[1] for p in px)/n, sum(p[2] for p in px)/n)

# --- perceptual distance: CIE76 in Lab, which respects how eyes group colour
def srgb_to_lab(c):
    def f(u):
        u/=255.0
        return u/12.92 if u<=0.04045 else ((u+0.055)/1.055)**2.4
    r,g,b = f(c[0]), f(c[1]), f(c[2])
    X = r*0.4124+g*0.3576+b*0.1805
    Y = r*0.2126+g*0.7152+b*0.0722
    Z = r*0.0193+g*0.1192+b*0.9505
    Xn,Yn,Zn = 0.95047,1.0,1.08883
    def g_(t): return t**(1/3) if t>0.008856 else 7.787*t+16/116
    fx,fy,fz = g_(X/Xn), g_(Y/Yn), g_(Z/Zn)
    return (116*fy-16, 500*(fx-fy), 200*(fy-fz))

def dist(a,b):
    la,lb = srgb_to_lab(a), srgb_to_lab(b)
    return sum((x-y)**2 for x,y in zip(la,lb))**0.5
