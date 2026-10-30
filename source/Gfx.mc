using Toybox.Graphics;
using Toybox.Math;

// Drawing in tank units. The CYD draws on an 80-unit grid; here each unit is
// a 3x3 screen cell, so a point becomes a 3x3 block, a line is drawn 3 wide
// (the caller sets the pen width once per frame) and a circle of radius r
// becomes radius 3r+1. The grid bitmap drawn over the frame afterwards cuts
// the corners off every cell, which gives the CYD's plus-shaped dots.
// Coordinates are truncated toward zero first, as the CYD's int16 calls do.
module Gfx {
    const S = 3;

    // Tank unit -> screen pixel at the centre of the cell.
    function sx(v) {
        return v.toNumber() * S + 1;
    }

    function px(dc, x, y, c) {
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x.toNumber() * S, y.toNumber() * S, S, S);
    }

    function line(dc, x0, y0, x1, y1, c) {
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(sx(x0), sx(y0), sx(x1), sx(y1));
    }

    // The radius keeps its fraction (the CYD rounds it down to a whole
    // unit, which turned every small fish into radius-1 dots).
    function circle(dc, x, y, r, c) {
        var rp = (r * S).toNumber();
        if (rp < 0) {
            rp = 0;
        }
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(sx(x), sx(y), rp + 1);
    }

    function tri(dc, x0, y0, x1, y1, x2, y2, c) {
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[sx(x0), sx(y0)], [sx(x1), sx(y1)], [sx(x2), sx(y2)]]);
    }

    // Pixel-precision versions for the outline drawings: tank units times 3
    // without snapping to a cell, so an outline can put a corner anywhere.
    // The dot grid drawn over the frame still gives them the CYD look.
    function fx(v) {
        return (v * S + 1.5).toNumber();
    }

    // pts is an array of [x, y] pairs in tank units.
    function polyF(dc, pts, c) {
        var n = pts.size();
        var out = new [n];
        for (var i = 0; i < n; i++) {
            out[i] = [fx(pts[i][0]), fx(pts[i][1])];
        }
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(out);
    }

    function lineF(dc, x0, y0, x1, y1, c) {
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(fx(x0), fx(y0), fx(x1), fx(y1));
    }

    function circleF(dc, x, y, r, c) {
        var rp = (r * S).toNumber();
        if (rp < 0) {
            rp = 0;
        }
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(fx(x), fx(y), rp + 1);
    }

    // GFX_Lite drawCircleArray: a row of circles of radius min(rad, length)
    // along the direction perpendicular to angle, max(rad, length/2) each way.
    function circleArray(dc, x, y, rad, length, angle, c) {
        var cosA = Math.cos(angle);
        var sinA = Math.sin(angle);
        var rr = rad;
        var ll = length;
        if (length < rad) {
            rr = length;
            ll = rad;
        }
        var n = (ll / 2.0).toNumber();
        if (rr.toNumber() > n) {
            n = rr.toNumber();
        }
        var xi = x.toNumber();
        var yi = y.toNumber();
        for (var i = -n; i <= n; i++) {
            var dx = i * -sinA;
            var dy = i * cosA;
            circle(dc, (xi + dx).toNumber(), (yi + dy).toNumber(), rr, c);
        }
    }
}
