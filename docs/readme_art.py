#!/usr/bin/env python3
# README images for the Garmin aquarium. Nothing here is captured from the
# watch. The pictures are drawn by a Python copy of the app's drawing code
# (art_lib.py: 3 px per tank unit, the dot grid, the outline fish), and the
# animation runs a Python copy of the app's swimming, feeding and flocking
# rules (Motion.mc, Creature.mc, Tank.mc, Boids.mc, Plant.mc, Food.mc) at
# about the frame rate measured on the watch (one frame every 300 ms).
#   creatures.png  a sheet of the creatures
#   guide.png      the Reef Guide index and a species page
#   demo.gif       an example tank on a first run, 15 seconds, with a grey
#                  ring marking the edge of the watch screen
# Usage (needs Pillow): python3 readme_art.py <source/Species.mc> <output dir>
import math, re, sys, random
from PIL import Image, ImageDraw, ImageFont
sys.path.insert(0, __file__.rsplit("/", 1)[0])
from art_lib import Gfx, grid, Creature, FAMILIES, S, EYE

species_mc = open(sys.argv[1]).read()
OUT = sys.argv[2]
TWO_PI = 6.283185

def arr(name):
    m = re.search(r'var %s = \[(.*?)\];' % name, species_mc, re.S)
    return [x.strip().strip('"') for x in m.group(1).split(',')]
NAME = arr("NAME"); DESC = arr("DESC")
SIL = [int(x) for x in arr("SIL")]; MOTION = [int(x) for x in arr("MOTION")]
HUE = [int(x) for x in arr("HUE")]; SAT = [int(x) for x in arr("SAT")]; VAL = [int(x) for x in arr("VAL")]
SIZE = [int(x) for x in arr("SIZE")]; SWIM = [int(x) for x in arr("SWIM")]

# ---------------------------------------------------------------- colour
# FastLED hsv2rgb_rainbow, as Colour.mc
def scale8(i, s): return (i * (s + 1)) >> 8
def scale8v(i, s):
    j = (i * s) >> 8
    if i != 0 and s != 0: j += 1
    return j
def hsv(hue, sat, val):
    offset8 = (hue & 0x1F) << 3; third = scale8(offset8, 85)
    if not (hue & 0x80):
        if not (hue & 0x40):
            if not (hue & 0x20): r, g, b = 255 - third, third, 0
            else: r, g, b = 171, 85 + third, 0
        else:
            if not (hue & 0x20): tt = scale8(offset8, 170); r, g, b = 171 - tt, 170 + third, 0
            else: r, g, b = 0, 255 - third, third
    else:
        if not (hue & 0x40):
            if not (hue & 0x20): tt = scale8(offset8, 170); r, g, b = 0, 171 - tt, 85 + tt
            else: r, g, b = third, 0, 255 - third
        else:
            if not (hue & 0x20): r, g, b = 85 + third, 0, 171 - third
            else: r, g, b = 170 + third, 0, 85 - third
    if sat != 255:
        if sat == 0: r = g = b = 255
        else:
            desat = 255 - sat; desat = scale8v(desat, desat); ss = 255 - desat
            r = scale8(r, ss) + desat; g = scale8(g, ss) + desat; b = scale8(b, ss) + desat
    if val != 255:
        v = scale8v(val, val)
        if v == 0: r = g = b = 0
        else: r, g, b = scale8(r, v), scale8(g, v), scale8(b, v)
    return (min(r, 255), min(g, 255), min(b, 255))

def scaled(c, f):
    return tuple(int(v * f) for v in c)

# Creature.refreshColours: fixed colours for the big species, otherwise the
# species hue at saturation 115; everything fades past adult age
FIXED = {19: (150, 158, 170), 20: (96, 116, 140), 22: (62, 84, 124), 21: (70, 60, 110), 15: (110, 140, 55)}
def creature_colour(sid, age):
    af = 1.0
    if age >= 0.7:
        af = 1.0 - ((age - 0.7) / 0.3) * 0.5
    if SIL[sid] in FIXED:
        return scaled(FIXED[SIL[sid]], af)
    v = max(0, min(255, int(255.0 * af)))
    return hsv(HUE[sid], 115, v)

def size_scale(sid):
    return [0.55, 0.75, 1.0, 1.25][SIZE[sid]]

# silhouette -> art_lib drawing family
FAM_OF_SIL = {1: "chromis", 2: "fusilier", 3: "anthias", 4: "cardinal", 11: "clownfish", 12: "bluetang",
              15: "turtle", 19: "shark", 20: "whaleshark", 21: "manta", 22: "whale"}

def draw_species(g, sid, x, y, angle, age=0.6):
    """Draw species sid at tank (x, y) the way Creature.draw does."""
    fam = FAM_OF_SIL[SIL[sid]]
    c = Creature(g, x, y, angle, size_scale(sid), creature_colour(sid, age), False)
    c.fam = fam
    age_size = max(0.0, min(age, 0.98))
    c.size = age_size * 1.8          # Cfg.CREATURE_SCALE; outlines use size / (0.6 * 1.8)
    if sid == 95:
        c.tip = (240, 240, 245)      # whitetip reef shark
    if fam in ("clownfish", "bluetang"):
        getattr(c, "cyd_" + fam)()
    else:
        getattr(c, "new_" + fam)()

def load_font(name, size):
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/" + name, size)
    except Exception:
        return ImageFont.load_default()
FONT = load_font("DejaVuSans.ttf", 11)        # stand-in for the watch's FONT_XTINY
FONT_NAME = load_font("DejaVuSans.ttf", 14)   # stand-in for FONT_SMALL

def round_mask(im):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).ellipse((0, 0, im.width - 1, im.height - 1), fill=255)
    out = Image.new("RGB", im.size, (0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out

# ------------------------------------------------------------ creatures.png
PICKS = [(0, "chromis"), (28, "fusilier"), (38, "anthias"), (57, "cardinal"),
         (88, "clownfish"), (72, "blue tang"), (94, "blacktip shark"), (95, "whitetip shark"),
         (96, "whale shark"), (98, "humpback"), (97, "reef manta"), (90, "sea turtle")]
T = 120
COLS = 4
rows = (len(PICKS) + COLS - 1) // COLS
sheet = Image.new("RGB", (COLS * T, rows * (T + 15)), (0, 0, 0))
D = ImageDraw.Draw(sheet)
for n, (sid, label) in enumerate(PICKS):
    tile = Image.new("RGB", (T, T), (0, 0, 0))
    draw_species(Gfx(tile), sid, T / 2 / S + 1, T / 2 / S, 0.0)
    grid(tile)
    x = (n % COLS) * T; y = (n // COLS) * (T + 15)
    sheet.paste(tile, (x, y))
    D.text((x + T // 2, y + T + 6), label, fill=(190, 190, 190), font=FONT, anchor="mm")
sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(OUT + "/creatures.png")

# ------------------------------------------------------------ guide.png
INK = (25, 35, 45)
def portrait(d, sid, cx, cy, k, found):
    """Portrait.draw from Guide.mc (the silhouettes on the page shown)."""
    sil = SIL[sid]
    body = hsv(HUE[sid], SAT[sid], VAL[sid]) if found else INK
    white = (245, 245, 250) if found else INK
    yellow = (255, 220, 40) if found else INK
    black = (20, 20, 30) if found else INK
    limb = (100, 150, 90) if found else INK
    def circle(ox, oy, r, c):
        d.ellipse((cx + ox * k - r * k - 1, cy + oy * k - r * k - 1, cx + ox * k + r * k + 1, cy + oy * k + r * k + 1), fill=c)
    def line(x0, y0, x1, y1, c):
        d.line((cx + int(x0 * k), cy + int(y0 * k), cx + int(x1 * k), cy + int(y1 * k)), fill=c, width=k)
    def px(ox, oy, c):
        d.rectangle((cx + ox * k - k // 2, cy + oy * k - k // 2, cx + ox * k - k // 2 + k - 1, cy + oy * k - k // 2 + k - 1), fill=c)
    def tri(x0, y0, x1, y1, x2, y2, c):
        d.polygon([(cx + x0 * k, cy + y0 * k), (cx + x1 * k, cy + y1 * k), (cx + x2 * k, cy + y2 * k)], fill=c)
    if sil == 11:
        circle(0, 0, 4, body); circle(-3, 0, 3, body); circle(2, 0, 2, white); circle(-1, 0, 2, white); circle(-4, 0, 1, white)
    elif sil == 14:
        circle(0, 0, 3, white); circle(-1, 0, 3, black); circle(2, 0, 2, yellow); line(0, -3, 1, -9, white)
    elif sil == 15:
        circle(0, 0, 4, body); circle(5, 0, 2, limb)
        line(-2, -4, -5, -6, limb); line(-2, 4, -5, 6, limb); line(2, -4, 4, -6, limb); line(2, 4, 4, 6, limb)
    elif sil == 16:
        for s_ in range(5):
            a = -math.pi / 2 + s_ * TWO_PI / 5
            ex, ey = math.cos(a) * 5, math.sin(a) * 5
            line(0, 0, ex, ey, body); circle(int(ex), int(ey), 1, body)
        circle(0, 0, 2, body)
    elif sil == 17:
        for n_ in range(6):
            circle(-4 + n_, 1 if n_ % 2 else -1, 1, body)
        circle(3, 0, 2, body)
    elif sil == 18:
        circle(0, -1, 3, body)
        for o in range(5):
            a = math.pi * 0.65 + o * 0.2
            line(0, 1, math.cos(a) * 5, 1 + math.sin(a) * 5, body)
    elif sil == 19:
        circle(0, 0, 2, body); circle(-3, 0, 2, body); circle(3, 0, 1, body); line(0, -2, 1, -5, body); line(-5, -2, -5, 2, body)
    elif sil == 9:
        circle(0, 0, 3, body); tri(-5, 0, -2, -2, -2, 2, body)
    elif sil == 10:
        circle(0, 0, 3, body); circle(4, 0, 1, body); tri(-5, 0, -2, -2, -2, 2, body)
    elif sil == 5:
        circle(0, 0, 3, body); line(-1, -3, -1, 3, black); line(1, -3, 1, 3, black)
    else:
        circle(0, 0, 3, body); circle(-3, 0, 2, body); tri(4, 0, 2, -2, 2, 2, body)

BG = (4, 12, 22); TITLE = (224, 248, 238); MUTED = (120, 160, 150); ACCENT = (255, 210, 90)
PER_PAGE = 12; GCOLS = 3; CELL_W = 60; CELL_H = 46; GRID_X = 30; GRID_Y = 40
# an example guide part way through: the start entries, a spread of common
# fish, and most of page 8
FOUND = {99, 100, 101, 102, 0, 3, 5, 10, 17, 25, 28, 30, 33, 38, 40, 47, 57, 60, 64,
         84, 86, 88, 89, 90, 91, 93, 94}
PAGE = 7
SEL = 94

def guide_index():
    im = Image.new("RGB", (240, 240), BG)
    d = ImageDraw.Draw(im)
    for slot in range(PER_PAGE):
        sid = PAGE * PER_PAGE + slot
        cx = GRID_X + (slot % GCOLS) * CELL_W + CELL_W // 2
        cy = GRID_Y + (slot // GCOLS) * CELL_H + CELL_H // 2
        found = sid in FOUND
        portrait(d, sid, cx, cy - 9, 2, found)
        if not found:
            d.text((cx, cy + 13), "?", fill=MUTED, font=FONT, anchor="mm")
        if sid == SEL:
            d.rounded_rectangle((cx - CELL_W // 2 + 2, cy - CELL_H // 2 + 1, cx + CELL_W // 2 - 2, cy + CELL_H // 2 - 1), 4, outline=ACCENT)
    grid(im)
    d = ImageDraw.Draw(im)
    d.text((120, 10), "REEF GUIDE", fill=TITLE, font=FONT, anchor="mm")
    d.text((120, 26), "%d/103  P%d/9" % (len(FOUND), PAGE + 1), fill=MUTED, font=FONT, anchor="mm")
    return im

def guide_detail(sid):
    im = Image.new("RGB", (240, 240), BG)
    d = ImageDraw.Draw(im)
    portrait(d, sid, 120, 58, 5, True)
    grid(im)
    d = ImageDraw.Draw(im)
    d.text((120, 94), NAME[sid], fill=TITLE, font=FONT_NAME, anchor="mm")
    lines = []; cur = ""
    for w in DESC[sid].split(" "):
        t = (cur + " " + w).strip()
        if d.textlength(t, font=FONT) <= 170 or not cur:
            cur = t
        else:
            lines.append(cur); cur = w
    if cur:
        lines.append(cur)
    y = 116
    for l in lines[:4]:
        d.text((120, y), l, fill=MUTED, font=FONT, anchor="mm"); y += 14
    d.text((120, 204), "SEEN 3", fill=ACCENT, font=FONT, anchor="mm")
    return im

gi = round_mask(guide_index()).resize((480, 480), Image.NEAREST)
gd = round_mask(guide_detail(SEL)).resize((480, 480), Image.NEAREST)
both = Image.new("RGB", (980, 480), (0, 0, 0))
both.paste(gi, (0, 0)); both.paste(gd, (500, 0))
both.save(OUT + "/guide.png")

# ------------------------------------------------------------ the tank
R = 40.0; C = 40.0; KEEP_R = 34.0; DT = 100 / 33.333   # Cfg.R, Cfg.C, Cfg.KEEP_R, Cfg.dt()

class Rnd:
    """Rnd.mc: below(n), range(a, b), unit(), signed()."""
    def __init__(self, seed): self.r = random.Random(seed)
    def below(self, n): return 0 if n <= 0 else self.r.randrange(n)
    def range(self, a, b): return a if b <= a else a + self.below(b - a)
    def unit(self): return self.below(10001) / 10000.0
    def signed(self): return self.unit() * 2.0 - 1.0

class Motion:
    """Motion.mc"""
    MAX_FORCE = 0.0375; FOOD_FORCE = 0.075; BOUNDARY_FORCE = 0.0025
    def __init__(self, kind, x, y, rnd):
        self.rnd = rnd
        self.px, self.py = float(x), float(y)
        self.ax = self.ay = 0.0
        self.angleOffset = rnd.unit() * TWO_PI
        if kind == 1:   p = (40, 5, 10, 0.001, 1, False, True)     # turtle
        elif kind == 2: p = (30, 10, 5, 0.005, 2, False, True)     # star
        elif kind == 3: p = (40, 20, 5, 0.005, 6, True, True)      # snake
        elif kind == 4: p = (35, 5, 8, 0.002, 0, False, False)     # octopus
        else:           p = (30, 10, 2, 0.002, 6, True, True)      # fish
        self.maxSpeed = p[0] / 80.0; self.minSpeed = p[1] / 80.0; self.sinAmp = p[2] / 80.0
        self.sinFreq = p[3]; self.noiseAmp = p[4] / 80.0; self.sideSine = p[5]; self.useNoise = p[6]
        m = 0.0
        while m < 5.0:
            self.vx = float(rnd.range(-10, 10)); self.vy = float(rnd.range(-10, 10))
            m = math.hypot(self.vx, self.vy)
        self.vx /= 80.0; self.vy /= 80.0
        self.angle = math.atan2(self.vy, self.vx)
        self.wander = 0.0
        self.outOfBoundary = False; self.followingFood = False
        self.foodX = self.foodY = 0.0
    def applyForce(self, fx, fy):
        self.ax += fx; self.ay += fy
    def boundaryCheck(self, force):
        self.outOfBoundary = False
        dx = self.px - C; dy = self.py - C; d = math.hypot(dx, dy)
        if d > KEEP_R and d > 0.0:
            self.applyForce(-dx / d * force, -dy / d * force)
            self.outOfBoundary = True
    def sineMotion(self, now):
        theta = math.atan2(self.vy, self.vx)
        if self.sideSine:
            theta += math.pi / 2.0
        y_off = math.sin(now * self.sinFreq + self.angleOffset) * self.sinAmp
        self.applyForce(math.cos(theta) * y_off, math.sin(theta) * y_off)
    def noiseMotion(self):
        self.wander += self.rnd.signed() * 0.4
        self.wander = max(-1.0, min(1.0, self.wander))
        a = self.wander * TWO_PI
        mag = self.noiseAmp * self.wander
        self.applyForce(math.cos(a) * mag, math.sin(a) * mag)
    def update(self, age, now, dt):
        if age < 0.1:
            self.vx = self.vy = 0.0
            return
        self.boundaryCheck(self.BOUNDARY_FORCE * 10.0)   # stayInside is always true
        if not self.followingFood and not self.outOfBoundary:
            self.sineMotion(now)
            if self.useNoise:
                self.noiseMotion()
        elif self.followingFood:
            fx = self.foodX - self.px; fy = self.foodY - self.py; m = math.hypot(fx, fy)
            if m > 0.0:
                self.applyForce(fx / m * self.FOOD_FORCE, fy / m * self.FOOD_FORCE)
        dvx = self.vx + self.ax * dt; dvy = self.vy + self.ay * dt
        dm = math.hypot(dvx, dvy)
        if dm < self.minSpeed:
            if dm > 0.0:
                dvx = dvx / dm * self.minSpeed; dvy = dvy / dm * self.minSpeed
            else:
                dvx = self.minSpeed; dvy = 0.0
            dm = self.minSpeed
        if dm > self.maxSpeed:
            dvx = dvx / dm * self.maxSpeed; dvy = dvy / dm * self.maxSpeed
        self.vx, self.vy = dvx, dvy
        self.px += self.vx * dt; self.py += self.vy * dt
        self.ax = self.ay = 0.0
        self.angle = math.atan2(self.vy, self.vx)
        self.followingFood = False
    def followFood(self, x, y):
        self.foodX, self.foodY = x, y
        self.followingFood = True

class Food:
    """Food.mc"""
    def __init__(self, x):
        dx = max(-(R - 1.0), min(R - 1.0, x - C))
        self.x = C + dx
        h = math.sqrt(R * R - dx * dx)
        self.y = C - h; self.bottomY = C + h
        self.eaten = False; self.offScreen = False
    def update(self, dt):
        self.y += 0.3 * dt
        if self.y >= self.bottomY:
            self.offScreen = True
    def draw(self, g):
        if not self.eaten:
            g.px(self.x, self.y, (255, 180, 40)); g.px(self.x + 1.0, self.y, (220, 120, 20)); g.px(self.x, self.y + 1.0, (220, 120, 20))

class Fish:
    """Creature.mc (simulation side)"""
    def __init__(self, sid, x, y, start_age, now, rnd):
        self.id = sid
        self.age = start_age; self.last = now
        base = 1.0 / (7.0 * 24 * 60 * 60 * 1000)
        self.agingRate = base * (1.0 + 1.0 * (rnd.below(200) / 100.0 - 1.0))
        self.m = Motion(MOTION[sid], x, y, rnd)
        self.food = None
    def canTakeFood(self):
        return self.food is None and 0.1 < self.age < 0.9
    def update(self, now, dt):
        self.m.update(self.age, now, dt)
        self.age += (now - self.last) * self.agingRate; self.last = now
        if self.food is not None:
            if self.food.offScreen:
                self.food = None
            elif math.hypot(self.food.x - self.m.px, self.food.y - self.m.py) < 1.0:
                self.food.eaten = True
                self.food = None
            else:
                self.m.followFood(self.food.x, self.food.y)
        if self.age > 1.0:
            self.age = 0.0

class Boid:
    def __init__(self, x, y, rnd):
        self.x, self.y = x, y
        self.vx = rnd.below(256) / 255.0 - 0.5; self.vy = rnd.below(256) / 255.0 - 0.5
        self.maxSpeed = rnd.range(4, 8) / 10.0; self.maxForce = rnd.range(1, 2) / 10.0
        self.ax = self.ay = 0.0

class Boids:
    """Boids.mc (weekday separation and neighbour distances)"""
    def __init__(self, rnd):
        self.groups = []
        for _ in range(2):
            n = rnd.range(6, 10); grp = []
            for _ in range(n):
                a = rnd.unit() * TWO_PI; r = rnd.unit() * (R - 4.0)
                grp.append(Boid(C + math.cos(a) * r, C + math.sin(a) * r, rnd))
            self.groups.append(grp)
        self.sep = 4.0; self.nbr = 8.0
    def limitInto(self, b, fx, fy, w):
        fm = math.hypot(fx, fy)
        if fm > b.maxForce and fm > 0.0:
            fx = fx / fm * b.maxForce; fy = fy / fm * b.maxForce
        b.ax += fx * w; b.ay += fy * w
    def update(self, dt):
        for grp in self.groups:
            n = len(grp)
            for i in range(n):
                b = grp[i]
                sepX = sepY = 0.0; sepN = 0; aliX = aliY = 0.0; aliN = 0; cohX = cohY = 0.0
                for k in range(n):
                    if k == i: continue
                    o = grp[k]
                    dx = b.x - o.x; dy = b.y - o.y; d = math.hypot(dx, dy)
                    if d <= 0.0: continue
                    if d < self.sep:
                        sepX += dx / d / d; sepY += dy / d / d; sepN += 1
                    if d < self.nbr:
                        aliX += o.vx; aliY += o.vy; cohX += o.x; cohY += o.y; aliN += 1
                if sepN > 0:
                    sepX /= sepN; sepY /= sepN; sm = math.hypot(sepX, sepY)
                    if sm > 0.0:
                        self.limitInto(b, sepX / sm * b.maxSpeed - b.vx, sepY / sm * b.maxSpeed - b.vy, 1.5)
                if aliN > 0:
                    aliX /= aliN; aliY /= aliN; am = math.hypot(aliX, aliY)
                    if am > 0.0:
                        self.limitInto(b, aliX / am * b.maxSpeed - b.vx, aliY / am * b.maxSpeed - b.vy, 1.0)
                    cohX = cohX / aliN - b.x; cohY = cohY / aliN - b.y; cm = math.hypot(cohX, cohY)
                    if cm > 0.0:
                        self.limitInto(b, cohX / cm * b.maxSpeed - b.vx, cohY / cm * b.maxSpeed - b.vy, 1.0)
                ex = b.x - C; ey = b.y - C; ed = math.hypot(ex, ey)
                if ed > R - 2.0 and ed > 0.0:
                    self.limitInto(b, -ex / ed * b.maxSpeed - b.vx, -ey / ed * b.maxSpeed - b.vy, 1.0)
                b.vx += b.ax * dt; b.vy += b.ay * dt
                vm = math.hypot(b.vx, b.vy)
                if vm > b.maxSpeed and vm > 0.0:
                    b.vx = b.vx / vm * b.maxSpeed; b.vy = b.vy / vm * b.maxSpeed
                b.x += b.vx * dt; b.y += b.vy * dt
                b.ax = b.ay = 0.0
                ex = b.x - C; ey = b.y - C; ed = math.hypot(ex, ey)
                if ed > R - 1.0 and ed > 0.0:
                    b.x = C + ex / ed * (R - 1.0); b.y = C + ey / ed * (R - 1.0)
    def draw(self, g):
        for grp in self.groups:
            for b in grp:
                a = math.atan2(b.vy, b.vx); cx, cy = math.cos(a), math.sin(a)
                g.px(b.x + cx, b.y + cy, (40, 140, 220)); g.px(b.x, b.y, (40, 140, 220)); g.px(b.x - cx, b.y - cy, (20, 90, 180))

class Plant:
    """Plant.mc"""
    def __init__(self, x, y, anemone, rnd):
        self.x, self.y, self.anemone = x, y, anemone
        n_br = rnd.range(8, 12) if anemone else rnd.range(6, 10)
        size = 2.0 if anemone else 3.0
        self.branches = []
        for _ in range(n_br):
            a = rnd.range(3142, 6283) / 1000.0
            xs = [math.cos(a) * size]; ys = [math.sin(a) * size]
            n = rnd.range(3, 6) if anemone else rnd.range(4, 8)
            for j in range(1, n):
                th = math.atan2(ys[-1], xs[-1]); diff = 3.0 * math.pi / 2.0 - th
                if diff > math.pi: diff -= TWO_PI
                elif diff < -math.pi: diff += TWO_PI
                t2 = th + diff * 0.5
                xs.append(xs[-1] + math.cos(t2) * size); ys.append(ys[-1] + math.sin(t2) * size)
            self.branches.append((xs, ys, rnd.below(500) / 100.0))
    def draw(self, g, now):
        sf = 1.25
        stem, leaf, tip = ((40, 90, 70), (220, 140, 150), (255, 180, 170)) if self.anemone else ((20, 120, 45), (40, 180, 70), (255, 220, 60))
        for i, (xs, ys, ph) in enumerate(self.branches):
            g.line(xs[0] * sf + self.x, ys[0] * sf + self.y, self.x, self.y, stem)
            sway0 = math.sin(now / 10000.0 + ph)
            for j in range(1, len(xs)):
                sway = sway0 * 0.8 * j
                nx = xs[j] * sf + sway + self.x; ny = ys[j] * sf + self.y
                g.line(xs[j - 1] * sf + sway + self.x, ys[j - 1] * sf + self.y, nx, ny, stem)
                if j % 2 == 0:
                    g.px(nx + math.cos(now / 8000.0 + i) * 1.2, ny, leaf)
                if j == len(xs) - 1 and (sway0 - 0.5 > 0.0 or self.anemone):
                    g.circle(nx, ny, 1, tip)

class Tank:
    """Tank.mc on a first run (nothing in the Reef Guide yet), weekday, with
    the eight species given rather than picked at random."""
    def __init__(self, cast, rnd):
        now = 0
        self.rnd = rnd
        self.boids = Boids(rnd)
        self.seen = set()
        self.bubble = None; self.bubble_until = 0
        self.discover(99, now)
        self.plants = []
        for i in range(3):
            a = math.radians(70.0 + 20.0 * i); rr = R + 7.0
            sp = 100 if i == 0 else 101
            self.plants.append(Plant(C + math.cos(a) * rr, C + math.sin(a) * rr, i == 0, rnd))
            self.discover(sp, now)
        self.fish = []
        for n, sid in enumerate(cast):
            self.spawn(n, sid, now)
        self.foods = []
        self.pellets_eaten = 0; self.pellets_missed = 0
        self.next_food_delay = 0
        self.schedule_food(True, now)
    def discover(self, sid, now):
        if sid not in self.seen:
            self.seen.add(sid)
            self.bubble = "NEW " + NAME[sid]; self.bubble_until = now + 2200
    def initial_age(self, n):
        if n == 0: return self.rnd.range(74, 84) / 100.0
        if n == 1: return self.rnd.range(66, 78) / 100.0
        return self.rnd.range(52, 69) / 100.0
    def spawn(self, n, sid, now):
        a = self.rnd.unit() * TWO_PI; r = self.rnd.unit() * (KEEP_R - 8.0)
        self.fish.append(Fish(sid, C + math.cos(a) * r, C + math.sin(a) * r, self.initial_age(n), now, self.rnd))
        self.discover(sid, now)
    def schedule_food(self, boot, now):
        self.last_food = now
        lo, hi = (1500, 3500) if boot else (5500, 12000)
        self.next_food_delay = self.rnd.range(lo, hi + 1)
    def add_food(self, x, now):
        f = Food(x); self.foods.append(f)
        self.discover(102, now)
        best = None; best_d = 1e9
        for c in self.fish:
            if not c.canTakeFood(): continue
            d = (c.m.px - f.x) ** 2 + (c.m.py - f.y) ** 2
            if d < best_d: best_d = d; best = c
        if best is not None:
            best.food = f
    def step(self, now):
        if now - self.last_food >= self.next_food_delay:
            if sum(1 for f in self.foods if not f.offScreen and not f.eaten) < 3:
                self.add_food(C + self.rnd.range(-30, 31), now)
            self.schedule_food(False, now)
        self.boids.update(DT)
        for c in self.fish:
            c.update(now, DT)
        keep = []
        for f in self.foods:
            f.update(DT)
            if f.eaten:
                self.pellets_eaten += 1
            elif f.offScreen:
                self.pellets_missed += 1
            else:
                keep.append(f)
        self.foods = keep
    def draw(self, now):
        im = Image.new("RGB", (240, 240), (0, 0, 0))
        g = Gfx(im)
        self.boids.draw(g)
        for c in self.fish:
            draw_species(g, c.id, c.m.px, c.m.py, c.m.angle, c.age)
        for f in self.foods:
            f.draw(g)
        for p in self.plants:
            p.draw(g, now)
        grid(im)
        if self.bubble is not None and now < self.bubble_until:
            d = ImageDraw.Draw(im)
            d.text((121, 41), self.bubble, fill=(0, 0, 0), font=FONT, anchor="mm")
            d.text((120, 40), self.bubble, fill=(255, 245, 180), font=FONT, anchor="mm")
        return round_mask(im)

# an example tank: clownfish, chromis, blacktip reef shark, fusilier, reef
# manta, anthias, cardinal, blue tang (the first gets the oldest boot age)
CAST = [88, 0, 94, 28, 97, 38, 57, 72]
tank = Tank(CAST, Rnd(24))   # a start with the fish spread out
FRAME_MS = 300

# A grey ring just outside the screen circle, so it is clear where the watch
# screen ends. The screen is 480 px here (2x); the ring sits outside it.
RING_W = 6
RING_GAP = 1
MARGIN = RING_GAP + RING_W + 3
def with_border(screen):
    size = screen.width + 2 * MARGIN
    out = Image.new("RGB", (size, size), (0, 0, 0))
    out.paste(screen, (MARGIN, MARGIN))
    c = size / 2.0
    r_out = screen.width / 2.0 + RING_GAP + RING_W
    ImageDraw.Draw(out).ellipse((c - r_out, c - r_out, c + r_out - 1, c + r_out - 1),
                                outline=(110, 110, 110), width=RING_W)
    return out

frames = []
for f in range(50):
    now = f * FRAME_MS
    if f > 0:
        tank.step(now)
    frames.append(with_border(tank.draw(now).resize((480, 480), Image.NEAREST)))
frames[0].save(OUT + "/demo.gif", save_all=True, append_images=frames[1:], duration=FRAME_MS, loop=0, optimize=True)
print("wrote creatures.png, guide.png, demo.gif")
