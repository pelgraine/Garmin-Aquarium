#!/usr/bin/env python3
# Python copy of the Garmin aquarium's drawing code, used by readme_art.py to
# draw the README images. Same primitives as Gfx.mc: 3 px per tank unit,
# truncated coordinates, filled circles, 3-wide lines, filled polygons, then
# the dot-grid mask. The new_* methods are the outline drawings that
# Creature.mc was translated from point for point; the cyd_* methods are the
# CYD originals the outlines replaced (none of them is the app's look now).
# It began as the mock-up script for choosing the outline look, which is why
# a few unused mock-up helpers remain at the end.
import math
from PIL import Image, ImageDraw

S = 3
EYE = (10, 10, 20)
SCALE = 1.8
SIZE = 0.6 * SCALE

class Gfx:
    def __init__(self, im):
        self.d = ImageDraw.Draw(im)
    def sx(self, v):
        return int(v) * S + 1
    def px(self, x, y, c):
        self.d.rectangle((int(x) * S, int(y) * S, int(x) * S + S - 1, int(y) * S + S - 1), fill=c)
    def line(self, x0, y0, x1, y1, c):
        self.d.line((self.sx(x0), self.sx(y0), self.sx(x1), self.sx(y1)), fill=c, width=S)
    def circle(self, x, y, r, c):
        rp = max(0, int(r * S)) + 1
        cx, cy = self.sx(x), self.sx(y)
        self.d.ellipse((cx - rp, cy - rp, cx + rp, cy + rp), fill=c)
    def poly(self, pts, c):
        self.d.polygon([(self.sx(x), self.sx(y)) for x, y in pts], fill=c)
    # pixel-precision versions (tank units * 3, not snapped to cells): what
    # fillPolygon/drawLine get on the watch when given screen coordinates
    def polyF(self, pts, c):
        self.d.polygon([(int(x * S + 1.5), int(y * S + 1.5)) for x, y in pts], fill=c)
    def lineF(self, x0, y0, x1, y1, c):
        self.d.line((int(x0 * S + 1.5), int(y0 * S + 1.5), int(x1 * S + 1.5), int(y1 * S + 1.5)), fill=c, width=S)
    def tri(self, x0, y0, x1, y1, x2, y2, c):
        self.poly([(x0, y0), (x1, y1), (x2, y2)], c)
    def circleArray(self, x, y, rad, length, angle, c):
        cosA, sinA = math.cos(angle), math.sin(angle)
        rr, ll = (rad, length) if length >= rad else (length, rad)
        n = max(int(ll / 2.0), int(rr))
        xi, yi = int(x), int(y)
        for i in range(-n, n + 1):
            self.circle(int(xi + i * -sinA), int(yi + i * cosA), rr, c)

def grid(im):
    px = im.load()
    w, h = im.size
    for cy in range(0, h, 3):
        for cx in range(0, w, 3):
            for dx, dy in ((0, 0), (2, 0), (0, 2), (2, 2)):
                px[cx + dx, cy + dy] = (0, 0, 0)

def darker(c, f=0.65):
    return tuple(int(v * f) for v in c)

def lighter(c, f=0.5):
    return tuple(int(v + (255 - v) * f) for v in c)

SEGS = [2, 3, 3, 3, 3, 2]

class Creature:
    def __init__(self, g, x, y, angle, sc, col, detail=False):
        self.g, self.x, self.y, self.angle, self.sc, self.col, self.detail = g, x, y, angle, sc, col, detail
        self.size = SIZE
        self.segX = [0.0] * 6; self.segY = [0.0] * 6; self.gap = 0.78

    # ---------- current CYD drawings ----------
    def placeSegments(self, cosA, sinA):
        self.segX[0] = self.x; self.segY[0] = self.y
        for i in range(1, 6):
            step = max(SEGS[i - 1], SEGS[i]) * self.size * self.gap * self.sc
            self.segX[i] = self.segX[i - 1] - cosA * step
            self.segY[i] = self.segY[i - 1] - sinA * step
    def drawOvalBody(self, c, fat, cosA, sinA):
        self.placeSegments(cosA, sinA)
        for i in range(6):
            t = i / 5.0
            r = max(1.0, SEGS[i] * self.size * self.sc * fat * (0.7 + 0.3 * math.sin(t * math.pi)))
            self.g.circle(self.segX[i], self.segY[i], r, c)
    def drawForkedTail(self, c, spread, length, cosA, sinA):
        tx, ty = self.segX[5], self.segY[5]
        bx = tx - cosA * self.size * length * self.sc; by = ty - sinA * self.size * length * self.sc
        ux = -sinA * self.size * spread * self.sc; uy = cosA * self.size * spread * self.sc
        self.g.line(tx, ty, bx + ux, by + uy, c); self.g.line(tx, ty, bx - ux, by - uy, c)
    def eye(self, ex, ey, cosA=None, sinA=None):
        self.g.px(ex, ey, EYE)
        if self.detail and cosA is not None:
            self.g.px(ex + cosA * 0.6, ey + sinA * 0.6, (240, 240, 255))

    def cyd_chromis(self):
        cosA, sinA = math.cos(self.angle), math.sin(self.angle)
        self.gap = 0.9
        self.drawOvalBody(self.col, 0.7, cosA, sinA)
        self.drawForkedTail(self.col, 2.4, 2.8, cosA, sinA)
        self.eye(self.x + cosA * self.size * 1.2 * self.sc, self.y + sinA * self.size * 1.2 * self.sc, cosA, sinA)
    def cyd_fusilier(self):
        cosA, sinA = math.cos(self.angle), math.sin(self.angle)
        self.gap = 1.05
        self.drawOvalBody(self.col, 0.65, cosA, sinA)
        self.drawForkedTail(self.col, 2.0, 3.2, cosA, sinA)
        if self.detail:
            s, sc = self.size, self.sc
            self.g.line(self.x + cosA * s * 1.5 * sc, self.y + sinA * s * 1.5 * sc,
                        self.x - cosA * s * 2.5 * sc, self.y - sinA * s * 2.5 * sc, (255, 230, 80))
        self.eye(self.x + cosA * self.size * 1.3 * self.sc, self.y + sinA * self.size * 1.3 * self.sc, cosA, sinA)
    def cyd_anthias(self):
        cosA, sinA = math.cos(self.angle), math.sin(self.angle)
        self.gap = 0.72
        self.placeSegments(cosA, sinA)
        for i in range(6):
            r = max(1.0, SEGS[i] * self.size * self.sc * 1.05)
            self.g.circle(self.segX[i], self.segY[i], r, self.col)
            self.g.px(self.segX[i] - sinA * r * 0.9, self.segY[i] + cosA * r * 0.9, self.col)
        self.drawForkedTail(self.col, 2.8, 2.2, cosA, sinA)
        self.g.line(self.x, self.y, self.x - sinA * self.size * 3.2 * self.sc, self.y + cosA * self.size * 3.2 * self.sc, self.col)
        self.eye(self.x + cosA * self.size * 1.0 * self.sc, self.y + sinA * self.size * 1.0 * self.sc, cosA, sinA)
    def cyd_cardinal(self):
        cosA, sinA = math.cos(self.angle), math.sin(self.angle)
        self.gap = 0.55
        self.drawOvalBody(self.col, 1.15, cosA, sinA)
        tx, ty = self.segX[5], self.segY[5]
        s, sc = self.size, self.sc
        self.g.tri(tx - cosA * s * 2.0 * sc, ty - sinA * s * 2.0 * sc, tx - sinA * s * 1.4 * sc, ty + cosA * s * 1.4 * sc,
                   tx + sinA * s * 1.4 * sc, ty - cosA * s * 1.4 * sc, self.col)
        ex = self.x + cosA * s * 0.9 * sc; ey = self.y + sinA * s * 0.9 * sc
        self.g.circle(ex, ey, max(1.0, 1.3 * sc), EYE)
        if self.detail:
            self.g.px(ex + cosA * 0.5, ey + sinA * 0.5, (240, 240, 255))
    def cyd_clownfish(self):
        cosA, sinA = math.cos(self.angle), math.sin(self.angle)
        white = (245, 245, 250)
        self.placeSegments(cosA, sinA)
        for i in range(6):
            self.g.circle(self.segX[i], self.segY[i], max(1.0, SEGS[i] * self.size * self.sc), self.col)
        for band in (1, 2, 3):
            self.g.circle(self.segX[band], self.segY[band], max(1.0, SEGS[band] * self.size * self.sc * 0.85), white)
            if self.detail:
                self.g.px(self.segX[band] + cosA, self.segY[band] + sinA, (15, 15, 20))
                self.g.px(self.segX[band] - cosA, self.segY[band] - sinA, (15, 15, 20))
        tx, ty = self.segX[5], self.segY[5]
        s, sc = self.size, self.sc
        self.g.tri(tx - cosA * s * 3.0 * sc, ty - sinA * s * 3.0 * sc, tx - sinA * s * 2.0 * sc, ty + cosA * s * 2.0 * sc,
                   tx + sinA * s * 2.0 * sc, ty - cosA * s * 2.0 * sc, self.col)
        self.eye(self.x + cosA * s * 1.2 * sc, self.y + sinA * s * 1.2 * sc, cosA, sinA)
    def cyd_bluetang(self):
        cosA, sinA = math.cos(self.angle), math.sin(self.angle)
        rad = max(2.0, 3.5 * self.size * self.sc)
        self.g.circle(self.x, self.y, rad, self.col)
        self.g.tri(self.x - cosA * rad * 1.4, self.y - sinA * rad * 1.4, self.x - sinA * rad * 0.9, self.y + cosA * rad * 0.9,
                   self.x + sinA * rad * 0.9, self.y - cosA * rad * 0.9, (255, 220, 40))
        if self.detail:
            mx = self.x + math.cos(self.angle + math.pi / 2) * rad * 0.15; my = self.y + math.sin(self.angle + math.pi / 2) * rad * 0.15
            self.g.circle(mx, my, max(1.0, rad * 0.25), (10, 10, 20))
            self.g.px(self.x + math.cos(self.angle - math.pi / 2) * rad * 0.85, self.y + math.sin(self.angle - math.pi / 2) * rad * 0.85, (255, 220, 40))
        self.eye(self.x + cosA * rad * 0.55, self.y + sinA * rad * 0.55, cosA, sinA)
    def cyd_shark(self):
        cosA, sinA = math.cos(self.angle), math.sin(self.angle)
        s = max(0.45, self.size * self.sc); ln = 7.0 * s; halfH = 1.6 * s
        for k in range(10):
            t = -0.9 + 0.18 * k
            self.g.circle(self.x + cosA * t * ln, self.y + sinA * t * ln, max(1.0, halfH * (1.0 - abs(t) * 0.55)), self.col)
        dx = self.x + cosA * ln * 0.1 - sinA * halfH * 2.2; dy = self.y + sinA * ln * 0.1 + cosA * halfH * 2.2
        self.g.line(self.x, self.y, dx, dy, self.col)
        if self.detail:
            self.g.circle(dx, dy, 1, (10, 10, 15))
        tx = self.x - cosA * ln; ty = self.y - sinA * ln
        ux = -sinA * halfH * 2.4; uy = cosA * halfH * 2.4
        self.g.line(tx, ty, tx + ux, ty + uy, self.col); self.g.line(tx, ty, tx - ux * 0.7, ty - uy * 0.7, self.col)
        self.g.px(self.x + cosA * ln * 0.55, self.y + sinA * ln * 0.55, EYE)
    def cyd_whaleshark(self):
        cosA, sinA = math.cos(self.angle), math.sin(self.angle)
        s = max(0.5, self.size * 1.35); ln = 10.0 * s
        for k in range(14):
            t = -0.95 + 0.14 * k
            self.g.circle(self.x + cosA * t * ln, self.y + sinA * t * ln, max(1.2, 2.2 * s * (1.0 - abs(t) * 0.4)), self.col)
        if self.detail:
            for i in range(-2, 3):
                self.g.px(self.x + cosA * i * 1.6 * s, self.y + sinA * i * 1.6 * s - cosA * 0.8 * s, (240, 240, 245))
        self.g.circle(self.x - cosA * ln, self.y - sinA * ln, max(1.0, 1.8 * s), self.col)
    def cyd_manta(self):
        cosA, sinA = math.cos(self.angle), math.sin(self.angle)
        s = max(0.5, self.size * 1.15)
        self.g.circle(self.x, self.y, max(2.0, 3.2 * s), self.col)
        wx = -sinA * 5.5 * s; wy = cosA * 5.5 * s
        self.g.tri(self.x + wx, self.y + wy, self.x - wx, self.y - wy, self.x - cosA * 2.0 * s, self.y - sinA * 2.0 * s, self.col)
        self.g.circle(self.x + cosA * 3.0 * s, self.y + sinA * 3.0 * s, max(1.0, 1.4 * s), self.col)
        self.g.line(self.x, self.y, self.x - cosA * 5.0 * s, self.y - sinA * 5.0 * s, self.col)
    def cyd_whale(self):
        cosA, sinA = math.cos(self.angle), math.sin(self.angle)
        s = max(0.55, self.size * 1.4); ln = 11.0 * s
        for k in range(16):
            t = -0.95 + 0.12 * k
            if t > 0.851: break
            self.g.circle(self.x + cosA * t * ln, self.y + sinA * t * ln, max(1.4, 2.4 * s * (1.0 - abs(t) * 0.35)), self.col)
        tx = self.x - cosA * ln; ty = self.y - sinA * ln
        ux = -sinA * 3.2 * s; uy = cosA * 3.2 * s
        self.g.line(tx + ux, ty + uy, tx - ux, ty - uy, self.col)
        if self.detail:
            self.g.px(self.x - sinA * 1.5 * s, self.y + cosA * 1.5 * s, (20, 20, 30))
    def cyd_turtle(self):
        cosA, sinA = math.cos(self.angle), math.sin(self.angle)
        s = max(0.35, self.size)
        rad2 = max(1, int(3.0 * s)); len2 = max(2, int(6.0 * 1.015 * s))
        shell = self.col; rim = darker(self.col, 0.75); limb = (140, 150, 80)
        self.g.circleArray(self.x, self.y, rad2, len2, self.angle + math.pi / 2, shell)
        if self.detail:
            self.g.circleArray(self.x, self.y, max(1, rad2 // 2), max(2, len2 // 2), self.angle + math.pi / 2, rim)
            for i in (-1, 0, 1):
                self.g.px(self.x + math.cos(self.angle + math.pi / 2) * i * rad2 * 0.6, self.y + math.sin(self.angle + math.pi / 2) * i * rad2 * 0.6, rim)
        hx = self.x + cosA * len2 * 0.75; hy = self.y + sinA * len2 * 0.75
        self.g.circle(hx, hy, max(1, int(rad2 * 0.55)), limb)
        self.g.px(hx + cosA, hy + sinA, EYE)
        for i in range(4):
            side = 1.0 if i % 2 == 0 else -1.0
            along = 0.35 if i < 2 else -0.35
            bx = self.x + cosA * len2 * along; by = self.y + sinA * len2 * along
            reach = side * (rad2 + 1.2 * s)
            fx = bx - sinA * reach; fy = by + cosA * reach
            self.g.line(bx, by, fx, fy, limb); self.g.circle(fx, fy, 1, limb)

    # ---------- option 2: fish outlines for the common four ----------
    # Local coordinates: +x forward, +u "up" (dorsal). The dorsal side is
    # kept upward whichever way the fish faces (mirrored when facing left),
    # the way sprite fish are flipped rather than rotated upside down.
    def place(self, pts, k):
        a = self.angle
        cosA, sinA = math.cos(a), math.sin(a)
        flip = -1.0 if cosA < 0 else 1.0
        out = []
        for fx, fu in pts:
            fx *= k; fu *= k * flip
            # forward = (cosA, sinA), up = (sinA, -cosA)
            out.append((self.x + cosA * fx + sinA * fu, self.y + sinA * fx - cosA * fu))
        return out
    def body(self, pts, k, c):
        self.g.polyF(self.place(pts, k), c)
    def pt(self, p, k):
        return self.place([p], k)[0]
    def dot(self, p, k, c):
        x, y = self.pt(p, k); self.g.px(x, y, c)
    def seg(self, p0, p1, k, c):
        (x0, y0), (x1, y1) = self.place([p0, p1], k); self.g.lineF(x0, y0, x1, y1, c)

    # outline size per family: these are the readable sizes on the watch
    # (chromis about 36 px nose to tail), scaled by age like the others
    KBASE = {"chromis": 1.1, "fusilier": 1.0, "anthias": 1.05, "cardinal": 1.15, "clownfish": 0.8, "bluetang": 1.0,
             "shark": 1.0625, "whaleshark": 1.0, "whale": 1.0, "manta": 1.0, "turtle": 1.0}
    def kfac(self):
        return self.size / SIZE * self.KBASE[self.fam]

    def new_chromis(self):
        k = self.kfac(); c = self.col; f = lighter(c)
        # deep damsel body, solid forked tail, dorsal and pectoral in a lighter tint
        self.body([(3.8, 0), (2.6, 1.6), (0.6, 2.2), (-1.6, 1.9), (-3.2, 0.9), (-3.2, -0.9), (-1.6, -1.9), (0.6, -2.2), (2.6, -1.6)], k, c)
        self.body([(-3.0, 0.9), (-6.2, 2.7), (-6.2, 1.1), (-4.6, 0), (-6.2, -1.1), (-6.2, -2.7), (-3.0, -0.9)], k, c)
        self.body([(-2.0, 1.8), (1.4, 2.0), (0.2, 3.5), (-1.4, 3.3)], k, f)
        self.body([(0.8, -0.6), (-0.9, -0.6), (-0.3, -2.4)], k, f)
        self.dot((2.4, 0.6), k, EYE); self.dot((3.0, 0.9), k, (240, 240, 255))
    def new_fusilier(self):
        k = self.kfac(); c = self.col; f = lighter(c)
        # slim torpedo, deep solid fork, small dorsal, pale lateral band
        self.body([(5.4, 0), (3.6, 1.2), (0, 1.6), (-3.4, 1.2), (-4.8, 0.5), (-4.8, -0.5), (-3.4, -1.2), (0, -1.6), (3.6, -1.2)], k, c)
        self.body([(-4.6, 0.6), (-7.8, 2.6), (-7.8, 1.0), (-6.2, 0), (-7.8, -1.0), (-7.8, -2.6), (-4.6, -0.6)], k, c)
        self.body([(-1.4, 1.4), (1.4, 1.5), (0.6, 2.7), (-0.8, 2.6)], k, f)
        self.body([(1.6, -0.5), (0.0, -0.5), (0.6, -1.9)], k, f)
        self.seg((3.2, 0.1), (-3.4, 0.1), k, f)
        self.dot((4.0, 0.3), k, EYE); self.dot((4.6, 0.5), k, (240, 240, 255))
    def new_anthias(self):
        k = self.kfac(); c = self.col; f = lighter(c)
        # deep body, solid lyre tail, long dorsal with a streamer
        self.body([(3.4, 0), (2.2, 2.0), (0, 2.5), (-2.0, 2.0), (-3.2, 0.9), (-3.2, -0.9), (-2.0, -2.0), (0, -2.5), (2.2, -2.0)], k, c)
        self.body([(-3.0, 1.0), (-6.6, 3.4), (-6.8, 1.6), (-4.8, 0), (-6.8, -1.6), (-6.6, -3.4), (-3.0, -1.0)], k, c)
        self.body([(-2.4, 2.0), (1.8, 2.2), (1.4, 3.6), (-2.8, 3.6)], k, f)
        self.body([(-2.8, 3.6), (-1.6, 3.6), (-4.0, 5.2)], k, f)
        self.body([(0.8, -0.9), (-0.9, -0.9), (-0.4, -2.8)], k, f)
        self.dot((2.2, 0.8), k, EYE); self.dot((2.8, 1.1), k, (240, 240, 255))
    def new_cardinal(self):
        k = self.kfac(); c = self.col; f = lighter(c)
        # compact rounded body, rounded tail, two small dorsals, big eye
        self.body([(3.0, 0), (2.2, 1.8), (0, 2.3), (-2.0, 1.8), (-3.0, 0.7), (-3.0, -0.7), (-2.0, -1.8), (0, -2.3), (2.2, -1.8)], k, c)
        self.body([(-2.8, 1.0), (-4.6, 2.0), (-5.4, 0.9), (-5.4, -0.9), (-4.6, -2.0), (-2.8, -1.0)], k, c)
        self.body([(-0.4, 2.1), (1.2, 2.1), (0.8, 3.4), (-0.6, 3.3)], k, f)
        self.body([(-2.4, 1.7), (-1.0, 1.9), (-1.4, 3.0), (-2.6, 2.8)], k, f)
        self.body([(0.8, -0.7), (-0.6, -0.7), (-0.1, -2.2)], k, f)
        ex, ey = self.pt((1.6, 0.5), k)
        self.g.circle(ex, ey, 0.7, EYE)
        self.dot((2.2, 0.9), k, (240, 240, 255))

    # ---------- outline clownfish and blue tang (v0.4) ----------
    def new_clownfish(self):
        k = self.kfac(); c = self.col; white = (245, 245, 250)
        # rounded orange body, rounded tail, notched dorsal, anal and pelvic
        # fins, three white bands edged in black (black shape, white over it)
        self.body([(-4.5, 0.7), (-5.5, 1.9), (-6.7, 2.5), (-7.7, 2.2), (-8.2, 1.2), (-8.3, 0.0), (-8.2, -1.2), (-7.7, -2.2), (-6.7, -2.5), (-5.5, -1.9), (-4.5, -0.7)], k, c)   # tail
        self.body([(3.2, 2.4), (1.8, 3.7), (0.4, 2.9), (-0.6, 3.8), (-1.8, 4.2), (-2.9, 3.7), (-3.5, 2.6), (-3.9, 1.0), (-2.8, 1.6), (-1.3, 2.2), (0.6, 2.5), (2.6, 2.5)], k, c)   # dorsal
        self.body([(-0.4, -2.2), (-1.0, -3.4), (-2.0, -3.9), (-3.0, -3.5), (-3.6, -2.2), (-3.8, -0.9), (-2.8, -1.5), (-1.3, -2.1)], k, c)   # anal
        self.body([(2.8, -2.1), (2.3, -3.4), (1.4, -3.7), (1.0, -2.3)], k, c)   # pelvic
        self.body([(6.3, 0.2), (6.0, 1.0), (5.3, 1.8), (4.2, 2.3), (2.6, 2.5), (0.6, 2.5), (-1.3, 2.2), (-2.8, 1.6), (-3.8, 1.0), (-4.7, 0.8), (-4.7, -0.8), (-3.8, -0.9), (-2.8, -1.5), (-1.3, -2.1), (0.4, -2.3), (2.4, -2.2), (4.2, -1.8), (5.4, -1.2), (6.1, -0.5)], k, c)   # body
        self.body([(2.5, 2.5), (2.6, 2.5), (4.2, 2.3), (4.3, 2.25), (3.9, 1.0), (3.8, 0.0), (3.9, -1.0), (4.2, -1.8), (2.4, -2.2), (2.1, -1.0), (2.0, 0.0), (2.1, 1.0)], k, EYE)   # head band
        self.body([(2.9, 2.46), (3.9, 2.34), (3.5, 1.0), (3.4, 0.0), (3.5, -1.0), (3.8, -1.89), (2.8, -2.11), (2.5, -1.0), (2.4, 0.0), (2.5, 1.0)], k, white)
        self.body([(-1.0, 2.25), (0.6, 2.5), (0.9, 2.5), (1.2, 1.2), (1.8, 0.2), (1.2, -0.9), (0.8, -2.28), (0.4, -2.3), (-1.0, -2.14), (-1.2, -0.6), (-1.2, 0.8)], k, EYE)   # middle band
        self.body([(-0.6, 2.31), (0.5, 2.48), (0.8, 1.2), (1.4, 0.2), (0.8, -0.9), (0.4, -2.3), (-0.6, -2.18), (-0.8, -0.6), (-0.8, 0.8)], k, white)
        self.body([(-4.4, 0.87), (-3.8, 1.0), (-2.8, 1.6), (-2.8, -1.5), (-3.8, -0.9), (-4.4, -0.83)], k, EYE)   # tail-base band
        self.body([(-4.0, 0.96), (-3.8, 1.0), (-3.2, 1.36), (-3.2, -1.26), (-3.8, -0.9), (-4.0, -0.88)], k, white)
        ex, ey = self.pt((4.85, 0.7), k)
        self.g.circle(ex, ey, 0.5, EYE)
        self.dot((5.3, 1.05), k, (240, 240, 255))
    def new_bluetang(self):
        k = self.kfac(); c = self.col; yellow = (255, 220, 40)
        # deep oval body, long dorsal and anal fins, yellow tail and pectoral,
        # black marking from the eye along the upper body round a blue patch
        self.body([(4.4, 2.9), (2.4, 4.1), (0.0, 4.4), (-2.4, 4.0), (-4.4, 3.0), (-5.6, 1.7), (-5.3, 1.4), (-4.0, 2.4), (-2.2, 3.2), (0.0, 3.6), (2.2, 3.5)], k, c)   # dorsal
        self.body([(1.4, -3.2), (-0.6, -4.1), (-2.8, -3.9), (-4.6, -2.6), (-5.6, -1.4), (-5.0, -1.3), (-3.6, -2.3), (-1.8, -3.0)], k, c)   # anal
        self.body([(4.2, -2.4), (3.4, -3.6), (2.6, -3.8), (2.8, -2.8)], k, c)   # pelvic
        self.body([(7.0, 0.3), (6.6, 1.0), (5.7, 2.1), (4.2, 3.0), (2.2, 3.5), (0.0, 3.6), (-2.2, 3.2), (-4.0, 2.4), (-5.3, 1.4), (-6.1, 0.8), (-6.1, -0.8), (-5.0, -1.3), (-3.6, -2.3), (-1.8, -3.0), (0.4, -3.3), (2.6, -3.0), (4.6, -2.3), (6.0, -1.2), (6.8, -0.4)], k, c)   # body
        self.body([(-5.4, 0.7), (-8.4, 2.7), (-9.2, 2.5), (-8.7, 0.0), (-9.2, -2.5), (-8.4, -2.7), (-5.4, -0.7)], k, yellow)   # tail
        self.body([(6.2, 1.2), (5.4, 2.4), (3.8, 3.1), (1.8, 3.35), (-0.4, 3.35), (-2.6, 2.95), (-4.4, 2.1), (-5.6, 1.0), (-5.9, 0.2), (-5.5, -0.4), (-4.0, -0.9), (-2.0, -1.1), (0.0, -0.9), (1.6, -0.4), (2.6, 0.6), (4.0, 0.9), (5.0, 0.4)], k, EYE)   # marking
        self.body([(0.9, 1.15), (0.68, 1.45), (0.07, 1.7), (-0.81, 1.83), (-1.79, 1.83), (-2.67, 1.7), (-3.28, 1.45), (-3.5, 1.15), (-3.28, 0.85), (-2.67, 0.6), (-1.79, 0.47), (-0.81, 0.47), (0.07, 0.6), (0.68, 0.85)], k, c)   # blue patch
        self.body([(4.0, -0.4), (2.0, -1.0), (0.6, -2.2), (1.4, -2.6), (3.0, -1.8)], k, yellow)   # pectoral
        self.dot((5.4, 1.3), k, (240, 240, 255))

    # ---------- outline versions of the big three ----------
    def new_shark(self):
        k = self.kfac(); c = self.col; f = lighter(c, 0.35); dk = getattr(self, 'tip', (20, 22, 30))
        # reef shark: pointed snout, tall first dorsal, pectoral, second
        # dorsal, heterocercal tail with the upper lobe larger, black fin tips
        self.body([(10, 0), (7, 1.6), (3, 2.4), (-2, 2.2), (-6, 1.4), (-8, 0.7), (-8, -0.7), (-6, -1.4), (-2, -2.0), (3, -2.2), (7, -1.5)], k, c)
        self.body([(7, -1.5), (3, -2.2), (-2, -2.0), (-6, -1.4), (-6, -0.4), (-2, -0.6), (3, -0.8)], k, f)      # pale belly
        self.body([(-1, 2.1), (3, 2.3), (1.2, 5.4)], k, c)                                                  # first dorsal
        self.body([(1.2, 5.4), (1.9, 4.3), (0.4, 4.2)], k, dk)                                              # black tip
        self.body([(-5.5, 1.3), (-3.8, 1.5), (-4.8, 2.7)], k, c)                                            # second dorsal
        self.body([(3, -1.9), (5.2, -2.0), (1.4, -4.8)], k, c)                                              # pectoral
        self.body([(1.4, -4.8), (2.4, -4.0), (1.0, -3.8)], k, dk)                                           # black tip
        self.body([(-7.5, 0.8), (-11.6, 4.4), (-11.8, 2.9), (-9.6, 0), (-11.0, -2.3), (-10.8, -3.1), (-7.5, -0.8)], k, c)   # tail
        self.dot((8.0, 0.4), k, EYE)
        for g in (5.2, 4.4, 3.6):                                                                           # gill slits
            self.dot((g, -0.4), k, (20, 22, 30))
    def new_whaleshark(self):
        k = self.kfac(); c = self.col; f = lighter(c, 0.35); sp = (235, 240, 245)
        # whale shark: broad flat head, wide body, sweeping dorsal, big
        # crescent tail, white spots in rows along the back
        self.body([(11.5, 0.9), (11.5, -0.9), (9, -2.6), (3, -3.4), (-4, -3.0), (-8, -1.8), (-10, -0.8), (-10, 0.8), (-8, 1.8), (-4, 3.0), (3, 3.4), (9, 2.6)], k, c)
        self.body([(9, -2.6), (3, -3.4), (-4, -3.0), (-8, -1.8), (-8, -0.6), (-4, -1.2), (3, -1.4), (9, -1.0)], k, f)   # pale belly
        self.body([(-3.5, 3.0), (1.5, 3.3), (-1.0, 6.2)], k, c)                                             # dorsal
        self.body([(3.5, -2.9), (7.0, -3.1), (2.5, -6.4)], k, c)                                            # pectoral
        self.body([(-9.5, 1.0), (-13.6, 5.2), (-13.9, 3.2), (-11.6, 0), (-13.7, -3.6), (-13.1, -4.9), (-9.5, -1.0)], k, c)   # tail
        for i in range(8):                                                                                  # spots
            x = 8.5 - i * 2.3
            self.dot((x, 1.0 + (i % 2) * 1.2), k, sp)
            if i % 2 == 0:
                self.dot((x - 1.1, 2.4), k, sp)
        self.dot((9.6, -0.6), k, EYE)
    def new_whale(self):
        k = self.kfac(); c = self.col; f = lighter(c, 0.4)
        # humpback: long body, small dorsal hump, very long pectoral flipper,
        # grooved pale throat, broad fluke
        self.body([(12.5, 0.4), (12.5, -0.8), (9, -2.4), (2, -3.0), (-5, -2.6), (-9, -1.6), (-11, -0.6), (-11, 0.6), (-9, 1.4), (-5, 2.2), (1, 2.6), (8, 2.0)], k, c)
        self.body([(10, -1.8), (2, -3.0), (-5, -2.6), (-5, -1.4), (2, -1.6), (10, -0.9)], k, f)             # throat
        self.body([(-4, 2.1), (-1, 2.5), (-2.6, 3.7)], k, c)                                                # hump
        self.body([(4.5, -2.3), (6.8, -2.6), (-1.0, -6.8), (-2.6, -5.6)], k, f)                             # flipper
        self.body([(-10.5, 0.6), (-14.2, 3.9), (-14.6, 2.6), (-12.6, 0), (-14.6, -2.6), (-14.2, -3.9), (-10.5, -0.6)], k, c)   # fluke
        self.dot((9.8, -0.9), k, EYE)
        self.dot((7.0, 1.9), k, (20, 20, 30))                                                               # blowhole

    # ---------- outline manta and turtle (both seen from above) ----------
    def new_manta(self):
        k = self.kfac(); c = self.col; f = lighter(c, 0.45); dk = (20, 22, 30)
        # diamond wings swept back, two cephalic lobes forward, long thin tail
        self.body([(4.5, 1.2), (1.5, 9.4), (-0.6, 9.2), (-4.0, 1.7), (-4.0, -1.7), (-0.6, -9.2), (1.5, -9.4), (4.5, -1.2)], k, c)
        self.body([(4.5, 1.2), (5.0, 1.0), (5.0, -1.0), (4.5, -1.2), (3.0, -1.4), (3.0, 1.4)], k, c)         # head block
        self.body([(5.0, 1.0), (7.0, 1.6), (7.4, 0.9), (5.0, 0.3)], k, c)                                 # cephalic lobe
        self.body([(5.0, -1.0), (7.0, -1.6), (7.4, -0.9), (5.0, -0.3)], k, c)
        self.body([(2.6, 1.6), (0.2, 5.4), (-1.6, 2.2)], k, f)                                            # shoulder patches
        self.body([(2.6, -1.6), (0.2, -5.4), (-1.6, -2.2)], k, f)
        self.seg((-4.0, 0), (-11.5, 0), k, c)                                                             # tail
        self.dot((4.6, 1.5), k, dk); self.dot((4.6, -1.5), k, dk)                                         # eyes
    def new_turtle(self):
        k = self.kfac(); c = self.col; d = darker(c, 0.6); lm = (150, 165, 95)
        # oval shell with a darker scute row, head, long front flippers,
        # short rear flippers, tail
        self.body([(2.8, 2.4), (3.6, 3.3), (-0.6, 7.2), (-1.8, 6.2), (0.4, 3.1)], k, lm)                  # front flippers
        self.body([(2.8, -2.4), (3.6, -3.3), (-0.6, -7.2), (-1.8, -6.2), (0.4, -3.1)], k, lm)
        self.body([(-3.0, 2.4), (-2.2, 3.2), (-5.2, 4.8), (-5.6, 3.7)], k, lm)                            # rear flippers
        self.body([(-3.0, -2.4), (-2.2, -3.2), (-5.2, -4.8), (-5.6, -3.7)], k, lm)
        self.body([(-4.3, 0.6), (-6.0, 0), (-4.3, -0.6)], k, lm)                                          # tail
        self.body([(4.0, 1.0), (6.6, 1.2), (7.5, 0), (6.6, -1.2), (4.0, -1.0)], k, lm)                    # head
        self.body([(4.2, 0), (3.2, 2.7), (0, 3.6), (-3.0, 3.0), (-4.6, 1.1), (-4.6, -1.1), (-3.0, -3.0), (0, -3.6), (3.2, -2.7)], k, c)   # shell
        self.body([(2.7, 0), (1.6, 1.5), (-1.4, 1.5), (-2.8, 0), (-1.4, -1.5), (1.6, -1.5)], k, d)         # centre scute
        self.body([(1.0, 1.8), (-1.0, 1.8), (-1.8, 2.8), (0.6, 2.9)], k, d)                               # side scutes
        self.body([(1.0, -1.8), (-1.0, -1.8), (-1.8, -2.8), (0.6, -2.9)], k, d)
        self.dot((6.6, 0.9), k, EYE); self.dot((6.6, -0.9), k, EYE)

FAMILIES = {
    "chromis": ((60, 200, 220), 0.55), "fusilier": ((230, 200, 40), 0.75),
    "anthias": ((240, 90, 60), 0.55), "cardinal": ((230, 230, 240), 0.55),
    "clownfish": ((255, 120, 20), 0.75), "bluetang": ((40, 60, 240), 1.0),
    "shark": ((150, 158, 170), 1.25), "whaleshark": ((96, 116, 140), 1.25),
    "manta": ((70, 60, 110), 1.25), "whale": ((62, 84, 124), 1.25), "turtle": ((110, 140, 55), 1.25),
}

def draw_creature(g, fam, x, y, angle, new=False, detail=False):
    col, sc = FAMILIES[fam]
    c = Creature(g, x, y, angle, sc, col, detail)
    c.fam = fam
    if new and fam in ("chromis", "fusilier", "anthias", "cardinal", "clownfish", "bluetang", "shark", "whaleshark", "whale", "manta", "turtle"):
        getattr(c, "new_" + fam)()
    else:
        getattr(c, "cyd_" + fam)()

def tile(fam, angle=0.0, new=False, detail=False, T=96):
    im = Image.new("RGB", (T, T), (0, 0, 0))
    g = Gfx(im)
    draw_creature(g, fam, T / 2 / S + 1, T / 2 / S, angle, new, detail)
    grid(im)
    return im

def tank(cast, new=False, detail=False):
    im = Image.new("RGB", (240, 240), (0, 0, 0))
    g = Gfx(im)
    for fam, x, y, ang in cast:
        draw_creature(g, fam, x, y, ang, new, detail)
    grid(im)
    # outside the circle is not screen
    mask = Image.new("L", (240, 240), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, 239, 239), fill=255)
    out = Image.new("RGB", (240, 240), (28, 28, 28))
    out.paste(im, (0, 0), mask)
    ImageDraw.Draw(out).ellipse((0, 0, 239, 239), outline=(70, 70, 70))
    return out

# casts: (family, tank x, tank y, angle)
CAST_NOW = [("chromis", 22, 24, 0.3), ("chromis", 50, 18, 2.9), ("chromis", 30, 50, -0.4), ("chromis", 56, 44, 3.3),
            ("fusilier", 40, 32, 0.1), ("anthias", 18, 40, 2.6), ("anthias", 52, 60, 0.5), ("cardinal", 36, 62, 3.0)]
CAST_TILT = [("shark", 38, 22, 0.15), ("turtle", 56, 46, 2.8), ("clownfish", 20, 44, -0.3), ("bluetang", 48, 60, 0.4),
             ("chromis", 24, 28, 2.7), ("chromis", 58, 30, 3.4), ("fusilier", 34, 52, 0.2), ("anthias", 18, 58, 2.5)]

