
import sys, os, struct, colorsys, io

DIR = "/mnt/kaun/wow-chat-2026"
if len(sys.argv) > 1 and sys.argv[1].startswith("--dir="):
    DIR = sys.argv.pop(1)[len("--dir="):]

DBC    = DIR + "/data-files/dbc/"
DATA   = os.path.dirname(DIR) + "/client/client-files/Data/enUS/"
PYLIBS = os.environ.get("PYLIBS", os.path.join(DIR, "libs", "pylibs"))
sys.path.insert(0, PYLIBS)

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
