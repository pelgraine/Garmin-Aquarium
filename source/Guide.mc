using Toybox.Application;
using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Math;
using Toybox.Lang;

// Port of lib/Aquarium/FieldGuide.h: which species have been seen, kept on
// the watch (Application.Storage, key "guide") instead of a LittleFS file.
class Guide {
    var seen;   // times seen per species; 0 = not found yet

    function initialize() {
        seen = new [Species.COUNT];
        for (var i = 0; i < Species.COUNT; i++) {
            seen[i] = 0;
        }
        var v = Application.Storage.getValue("guide");
        if (v != null && v instanceof Lang.Array && v.size() == Species.COUNT) {
            seen = v;
        }
    }

    // true the first time a species is seen
    function discover(id) {
        if (id < 0 || id >= Species.COUNT) {
            return false;
        }
        var first = (seen[id] == 0);
        seen[id] = seen[id] + 1;
        if (first || (seen[id] % 5) == 0) {
            save();
        }
        return first;
    }

    function isFound(id) {
        return seen[id] > 0;
    }

    function timesSeen(id) {
        return seen[id];
    }

    function foundCount() {
        var n = 0;
        for (var i = 0; i < Species.COUNT; i++) {
            if (seen[i] > 0) {
                n++;
            }
        }
        return n;
    }

    function save() {
        Application.Storage.setValue("guide", seen);
    }
}

// Port of drawSpeciesPortrait() from main_cyd.cpp: a fixed-pose picture of
// each silhouette, drawn at (cx, cy) on screen with k screen pixels per CYD
// pixel. Undiscovered species are drawn as a dark silhouette.
module Portrait {
    const INK = 0x19232D;

    function circle(dc, cx, cy, ox, oy, r, k, c) {
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx + ox * k, cy + oy * k, r * k + 1);
    }

    function line(dc, cx, cy, x0, y0, x1, y1, k, c) {
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx + (x0 * k).toNumber(), cy + (y0 * k).toNumber(),
                    cx + (x1 * k).toNumber(), cy + (y1 * k).toNumber());
    }

    function px(dc, cx, cy, ox, oy, k, c) {
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx + ox * k - k / 2, cy + oy * k - k / 2, k, k);
    }

    function tri(dc, cx, cy, x0, y0, x1, y1, x2, y2, k, c) {
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[cx + x0 * k, cy + y0 * k], [cx + x1 * k, cy + y1 * k], [cx + x2 * k, cy + y2 * k]]);
    }

    function draw(dc, id, cx, cy, k, found) {
        var sil = Species.SIL[id];
        var body = INK;
        var white = INK;
        var yellow = INK;
        var black = INK;
        var limb = INK;
        var eye = 0x0A0A14;
        if (found) {
            body = Colour.hsv(Species.HUE[id], Species.SAT[id], Species.VAL[id]);
            white = 0xF5F5FA;
            yellow = 0xFFDC28;
            black = 0x14141E;
            limb = 0x64965A;
        }
        dc.setPenWidth(k);
        if (sil == Species.SIL_CLOWNFISH) {
            circle(dc, cx, cy, 0, 0, 4, k, body);
            circle(dc, cx, cy, -3, 0, 3, k, body);
            circle(dc, cx, cy, 2, 0, 2, k, white);
            circle(dc, cx, cy, -1, 0, 2, k, white);
            circle(dc, cx, cy, -4, 0, 1, k, white);
        } else if (sil == Species.SIL_BLUE_TANG) {
            circle(dc, cx, cy, 0, 0, 4, k, body);
            tri(dc, cx, cy, -6, 0, -2, -3, -2, 3, k, yellow);
        } else if (sil == Species.SIL_YELLOW_TANG) {
            circle(dc, cx, cy, 0, 0, 4, k, body);
            tri(dc, cx, cy, 6, 0, 2, -2, 2, 2, k, body);
        } else if (sil == Species.SIL_MOORISH_IDOL) {
            circle(dc, cx, cy, 0, 0, 3, k, white);
            circle(dc, cx, cy, -1, 0, 3, k, black);
            circle(dc, cx, cy, 2, 0, 2, k, yellow);
            line(dc, cx, cy, 0, -3, 1, -9, k, white);
        } else if (sil == Species.SIL_TURTLE) {
            circle(dc, cx, cy, 0, 0, 4, k, body);
            circle(dc, cx, cy, 5, 0, 2, k, limb);
            line(dc, cx, cy, -2, -4, -5, -6, k, limb);
            line(dc, cx, cy, -2, 4, -5, 6, k, limb);
            line(dc, cx, cy, 2, -4, 4, -6, k, limb);
            line(dc, cx, cy, 2, 4, 4, 6, k, limb);
        } else if (sil == Species.SIL_STAR) {
            for (var s = 0; s < 5; s++) {
                var sa = -Math.PI / 2.0 + s * 6.283185 / 5.0;
                var ex = Math.cos(sa) * 5.0;
                var ey = Math.sin(sa) * 5.0;
                line(dc, cx, cy, 0, 0, ex, ey, k, body);
                circle(dc, cx, cy, ex.toNumber(), ey.toNumber(), 1, k, body);
            }
            circle(dc, cx, cy, 0, 0, 2, k, body);
        } else if (sil == Species.SIL_SNAKE) {
            for (var n = 0; n < 6; n++) {
                var oy = -1;
                if (n % 2 == 1) { oy = 1; }
                circle(dc, cx, cy, -4 + n, oy, 1, k, body);
            }
            circle(dc, cx, cy, 3, 0, 2, k, body);
        } else if (sil == Species.SIL_OCTOPUS) {
            circle(dc, cx, cy, 0, -1, 3, k, body);
            for (var o = 0; o < 5; o++) {
                var oa = Math.PI * 0.65 + o * 0.2;
                line(dc, cx, cy, 0, 1, Math.cos(oa) * 5.0, 1.0 + Math.sin(oa) * 5.0, k, body);
            }
        } else if (sil == Species.SIL_SHARK) {
            circle(dc, cx, cy, 0, 0, 2, k, body);
            circle(dc, cx, cy, -3, 0, 2, k, body);
            circle(dc, cx, cy, 3, 0, 1, k, body);
            line(dc, cx, cy, 0, -2, 1, -5, k, body);
            line(dc, cx, cy, -5, -2, -5, 2, k, body);
        } else if (sil == Species.SIL_WHALE_SHARK) {
            circle(dc, cx, cy, 0, 0, 3, k, body);
            circle(dc, cx, cy, -4, 0, 2, k, body);
            circle(dc, cx, cy, 4, 0, 2, k, body);
            if (found) {
                px(dc, cx, cy, -1, -1, k, 0xF0F0F5);
                px(dc, cx, cy, 1, -1, k, 0xF0F0F5);
            }
        } else if (sil == Species.SIL_MANTA) {
            circle(dc, cx, cy, 0, 0, 2, k, body);
            tri(dc, cx, cy, 0, 0, -6, -2, -6, 2, k, body);
            tri(dc, cx, cy, 0, 0, 6, -2, 6, 2, k, body);
            line(dc, cx, cy, 0, 0, 0, 5, k, body);
        } else if (sil == Species.SIL_WHALE) {
            circle(dc, cx, cy, 0, 0, 3, k, body);
            circle(dc, cx, cy, -4, 0, 2, k, body);
            circle(dc, cx, cy, 4, 0, 2, k, body);
            line(dc, cx, cy, -6, -2, -6, 2, k, body);
        } else if (sil == Species.SIL_PROP) {
            if (id == Species.ID_ANEMONE) {
                for (var p = -2; p <= 2; p++) {
                    line(dc, cx, cy, 0, 3, p * 2, -3, k, body);
                }
            } else if (id == Species.ID_KELP) {
                line(dc, cx, cy, 0, 5, -1, -5, k, body);
                line(dc, cx, cy, 0, 5, 2, -4, k, body);
            } else if (id == Species.ID_FISH_FLAKE) {
                px(dc, cx, cy, 0, 0, k, body);
                px(dc, cx, cy, 1, 0, k, body);
                px(dc, cx, cy, 0, 1, k, body);
            } else {
                px(dc, cx, cy, 1, 0, k, body);
                px(dc, cx, cy, 0, 0, k, body);
                px(dc, cx, cy, -1, 0, k, body);
            }
        } else if (sil == Species.SIL_CHROMIS_SHOAL) {
            circle(dc, cx, cy, 0, 0, 2, k, body);
            circle(dc, cx, cy, -2, 0, 2, k, body);
            line(dc, cx, cy, -4, 0, -6, -2, k, body);
            line(dc, cx, cy, -4, 0, -6, 2, k, body);
        } else if (sil == Species.SIL_FUSILIER) {
            circle(dc, cx, cy, 1, 0, 2, k, body);
            circle(dc, cx, cy, -2, 0, 1, k, body);
            circle(dc, cx, cy, 3, 0, 1, k, body);
            line(dc, cx, cy, -4, 0, -6, -2, k, body);
            line(dc, cx, cy, -4, 0, -6, 2, k, body);
        } else if (sil == Species.SIL_ANTHIAS) {
            circle(dc, cx, cy, 0, 0, 3, k, body);
            line(dc, cx, cy, 0, -3, 1, -6, k, body);
            line(dc, cx, cy, -3, 0, -5, -2, k, body);
            line(dc, cx, cy, -3, 0, -5, 2, k, body);
        } else if (sil == Species.SIL_CARDINAL) {
            circle(dc, cx, cy, 0, 0, 3, k, body);
            circle(dc, cx, cy, 2, -1, 1, k, eye);
            tri(dc, cx, cy, -4, 0, -2, -2, -2, 2, k, body);
        } else if (sil == Species.SIL_SERGEANT) {
            circle(dc, cx, cy, 0, 0, 3, k, body);
            line(dc, cx, cy, -1, -3, -1, 3, k, black);
            line(dc, cx, cy, 1, -3, 1, 3, k, black);
        } else if (sil == Species.SIL_SWEEPER) {
            circle(dc, cx, cy, 0, 0, 3, k, body);
            tri(dc, cx, cy, -4, 0, -2, -2, -2, 1, k, body);
        } else if (sil == Species.SIL_SILVERSIDE) {
            for (var q = -2; q <= 2; q++) {
                px(dc, cx, cy, q, 0, k, body);
            }
        } else if (sil == Species.SIL_DARTFISH) {
            px(dc, cx, cy, 3, 0, k, body);
            px(dc, cx, cy, 1, 0, k, body);
            px(dc, cx, cy, -1, 0, k, body);
            px(dc, cx, cy, -3, 0, k, white);
        } else if (sil == Species.SIL_SURGEON) {
            circle(dc, cx, cy, 0, 0, 3, k, body);
            tri(dc, cx, cy, -5, 0, -2, -2, -2, 2, k, body);
        } else if (sil == Species.SIL_UNICORN) {
            circle(dc, cx, cy, 0, 0, 3, k, body);
            circle(dc, cx, cy, 4, 0, 1, k, body);
            tri(dc, cx, cy, -5, 0, -2, -2, -2, 2, k, body);
        } else {
            // Schooler and default
            circle(dc, cx, cy, 0, 0, 3, k, body);
            circle(dc, cx, cy, -3, 0, 2, k, body);
            tri(dc, cx, cy, 4, 0, 2, -2, 2, 2, k, body);
        }
        dc.setPenWidth(1);
    }
}

// The Reef Guide screens: a paged index of silhouettes (3 x 4 a page) and a
// detail page. Up/Down move the highlight, Start opens, Back closes; a tap
// on a cell opens it too, and a swipe turns the page.
class GuideView extends WatchUi.View {
    const COLS = 3;
    const ROWS = 4;
    const PER_PAGE = 12;
    const CELL_W = 60;
    const CELL_H = 46;
    const GRID_X = 30;
    const GRID_Y = 40;
    const BG = 0x040C16;
    const TITLE = 0xE0F8EE;
    const MUTED = 0x78A096;
    const ACCENT = 0xFFD25A;
    const FONT = Graphics.FONT_XTINY;
    const MID = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    var sel = 0;
    var detail = false;
    var _grid = null;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc) {
        _grid = WatchUi.loadResource(Rez.Drawables.Grid);
    }

    function pageCount() {
        return (Species.COUNT + PER_PAGE - 1) / PER_PAGE;
    }

    function onUpdate(dc) {
        dc.setColor(BG, BG);
        dc.clear();
        if (detail) {
            drawDetail(dc);
        } else {
            drawIndex(dc);
        }
    }

    function drawIndex(dc) {
        var page = sel / PER_PAGE;
        var base = page * PER_PAGE;
        for (var slot = 0; slot < PER_PAGE; slot++) {
            var i = base + slot;
            if (i >= Species.COUNT) {
                break;
            }
            var col = slot % COLS;
            var row = slot / COLS;
            var cx = GRID_X + col * CELL_W + CELL_W / 2;
            var cy = GRID_Y + row * CELL_H + CELL_H / 2;
            var found = gGuide.isFound(i);
            Portrait.draw(dc, i, cx, cy - 9, 2, found);
            if (!found) {
                dc.setColor(MUTED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, cy + 13, FONT, "?", MID);
            }
            if (i == sel) {
                dc.setColor(ACCENT, Graphics.COLOR_TRANSPARENT);
                dc.drawRoundedRectangle(cx - CELL_W / 2 + 2, cy - CELL_H / 2 + 1, CELL_W - 4, CELL_H - 2, 4);
            }
        }
        if (_grid != null) {
            dc.drawBitmap(0, 0, _grid);
        }
        dc.setColor(TITLE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(120, 10, FONT, "REEF GUIDE", MID);
        dc.setColor(MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(120, 26, FONT, "" + gGuide.foundCount() + "/" + Species.COUNT + "  P" + (page + 1) + "/" + pageCount(), MID);
    }

    function drawDetail(dc) {
        var found = gGuide.isFound(sel);
        Portrait.draw(dc, sel, 120, 58, 5, found);
        if (_grid != null) {
            dc.drawBitmap(0, 0, _grid);
        }
        dc.setColor(TITLE, Graphics.COLOR_TRANSPARENT);
        var name = "???";
        if (found) {
            name = Species.NAME[sel];
        }
        dc.drawText(120, 94, Graphics.FONT_SMALL, name, MID);
        var fh = dc.getFontHeight(FONT);
        var y = 116;
        if (!found) {
            dc.setColor(MUTED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(120, y, FONT, "STILL HIDDEN", MID);
            return;
        }
        // wrap the description into lines no wider than 170 px
        var words = splitWords(Species.DESC[sel]);
        var lineText = "";
        var lines = 0;
        dc.setColor(MUTED, Graphics.COLOR_TRANSPARENT);
        for (var w = 0; w < words.size(); w++) {
            var trial = words[w];
            if (lineText.length() > 0) {
                trial = lineText + " " + words[w];
            }
            if (dc.getTextWidthInPixels(trial, FONT) <= 170 || lineText.length() == 0) {
                lineText = trial;
            } else {
                dc.drawText(120, y, FONT, lineText, MID);
                y += fh;
                lines++;
                lineText = words[w];
                if (lines >= 4) {
                    lineText = "";
                    break;
                }
            }
        }
        if (lineText.length() > 0 && lines < 4) {
            dc.drawText(120, y, FONT, lineText, MID);
        }
        dc.setColor(ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(120, 204, FONT, "SEEN " + gGuide.timesSeen(sel), MID);
    }

    function splitWords(s) {
        var out = [];
        var start = 0;
        var n = s.length();
        for (var i = 0; i <= n; i++) {
            if (i == n || s.substring(i, i + 1).equals(" ")) {
                if (i > start) {
                    out.add(s.substring(start, i));
                }
                start = i + 1;
            }
        }
        return out;
    }

    function move(d) {
        if (detail) {
            return;
        }
        sel = (sel + d + Species.COUNT) % Species.COUNT;
        WatchUi.requestUpdate();
    }

    function page(d) {
        if (detail) {
            return;
        }
        var p = sel / PER_PAGE + d;
        var n = pageCount();
        p = (p + n) % n;
        sel = p * PER_PAGE;
        WatchUi.requestUpdate();
    }

    function open() {
        detail = true;
        WatchUi.requestUpdate();
    }

    // Back: true when it closed the detail page, false to leave the guide.
    function back() {
        if (detail) {
            detail = false;
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    function tapAt(x, y) {
        if (detail) {
            back();
            return;
        }
        var col = (x - GRID_X) / CELL_W;
        var row = (y - GRID_Y) / CELL_H;
        if (x < GRID_X || y < GRID_Y || col < 0 || col >= COLS || row < 0 || row >= ROWS) {
            return;
        }
        var i = (sel / PER_PAGE) * PER_PAGE + row * COLS + col;
        if (i >= 0 && i < Species.COUNT) {
            sel = i;
            open();
        }
    }
}

class GuideDelegate extends WatchUi.BehaviorDelegate {
    var _v;

    function initialize(v) {
        BehaviorDelegate.initialize();
        _v = v;
    }

    function onNextPage() { _v.move(1); return true; }
    function onPreviousPage() { _v.move(-1); return true; }

    function onKey(evt) {
        if (evt.getKey() == WatchUi.KEY_ENTER) {
            _v.open();
            return true;
        }
        return false;
    }

    function onBack() {
        if (_v.back()) {
            return true;
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onTap(evt) {
        var c = evt.getCoordinates();
        _v.tapAt(c[0], c[1]);
        return true;
    }

    function onSwipe(evt) {
        var d = evt.getDirection();
        if (d == WatchUi.SWIPE_LEFT) { _v.page(1); return true; }
        if (d == WatchUi.SWIPE_RIGHT) { _v.page(-1); return true; }
        return false;
    }
}
