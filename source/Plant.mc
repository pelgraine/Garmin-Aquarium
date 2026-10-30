using Toybox.Math;

// Port of lib/Aquarium/Plants.h. Kelp or an anemone rooted at (x, y) on the
// lower edge of the tank, with branches that grow upward and sway.
class Plant {
    var x;
    var y;
    var species;
    var numBranches;
    var branchSize;
    var nodeX = [];     // per branch: array of node x offsets
    var nodeY = [];
    var phase = [];

    const TWO_PI = 6.283185;

    function initialize(px, py, speciesId) {
        x = px.toFloat();
        y = py.toFloat();
        species = speciesId;
        if (species == Species.ID_ANEMONE) {
            numBranches = Rnd.range(8, 12);
            branchSize = 2.0;
        } else {
            numBranches = Rnd.range(6, 10);
            branchSize = 3.0;
        }
        for (var i = 0; i < numBranches; i++) {
            // start direction somewhere in the upper half (PI .. 2 PI)
            var a = Rnd.range(3142, 6283) / 1000.0;
            var sx = Math.cos(a) * branchSize;
            var sy = Math.sin(a) * branchSize;
            var n = 0;
            if (species == Species.ID_ANEMONE) {
                n = Rnd.range(3, 6);
            } else {
                n = Rnd.range(4, 8);
            }
            var xs = new [n];
            var ys = new [n];
            xs[0] = sx;
            ys[0] = sy;
            for (var j = 1; j < n; j++) {
                // buildNode: bend the heading halfway toward straight up
                var theta = Math.atan2(ys[j - 1], xs[j - 1]);
                var diff = 3.0 * Math.PI / 2.0 - theta;
                if (diff > Math.PI) {
                    diff -= TWO_PI;
                } else if (diff < -Math.PI) {
                    diff += TWO_PI;
                }
                var t2 = theta + diff * 0.5;
                xs[j] = xs[j - 1] + Math.cos(t2) * branchSize;
                ys[j] = ys[j - 1] + Math.sin(t2) * branchSize;
            }
            nodeX.add(xs);
            nodeY.add(ys);
            phase.add(Rnd.below(500) / 100.0);
        }
    }

    // humidity is fixed at 50 on the CYD build: sizeFactor = 250 * 50% / 100
    function draw(dc, nowMs) {
        var sizeFactor = 1.25;
        var stem = 0x14782D;
        var leaf = 0x28B446;
        var tip = 0xFFDC3C;
        if (species == Species.ID_ANEMONE) {
            stem = 0x285A46;
            leaf = 0xDC8C96;
            tip = 0xFFB4AA;
        }
        var tSec = nowMs / 10000.0;
        var leafT = nowMs / 8000.0;
        for (var i = 0; i < numBranches; i++) {
            var xs = nodeX[i];
            var ys = nodeY[i];
            var n = xs.size();
            Gfx.line(dc, xs[0] * sizeFactor + x, ys[0] * sizeFactor + y, x, y, stem);
            var swayBase = Math.sin(tSec + phase[i]);
            for (var j = 1; j < n; j++) {
                var sway = swayBase * 0.8 * j;
                var pxj = xs[j - 1] * sizeFactor + sway + x;
                var pyj = ys[j - 1] * sizeFactor + y;
                var nx = xs[j] * sizeFactor + sway + x;
                var ny = ys[j] * sizeFactor + y;
                Gfx.line(dc, pxj, pyj, nx, ny, stem);
                if (j % 2 == 0) {
                    Gfx.px(dc, nx + Math.cos(leafT + i) * 1.2, ny, leaf);
                }
                if (j == n - 1) {
                    var glow = swayBase - 0.5;
                    if (glow > 0.0 || species == Species.ID_ANEMONE) {
                        Gfx.circle(dc, nx, ny, 1, tip);
                    }
                }
            }
        }
    }
}
