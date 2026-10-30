using Toybox.Math;

// Port of lib/Aquarium/Fish.h and the Body classes (FishBody, LargeFaunaBody,
// TurtleBody, StarBody, SnakeBody, OctopusBody). One object per creature:
// its species, age, motion and the drawing for its silhouette. Branches the
// CYD only draws in its near camera view are left out (there is no camera).
class Creature {
    var id;         // species index
    var sil;        // Species.SIL_*
    var kind;       // Species.MOTION_*
    var sc;         // size-class scale
    var age;
    var agingRate;
    var lastUpdateMs;
    var m;          // Motion
    var food = null;
    var plumpScale = 1.0;
    var plumpUntil = 0;
    var ageSize = 0.0; // age * plump, at most 0.98
    var size = 0.0;    // ageSize * Cfg.CREATURE_SCALE (the CYD-style drawings)
    var col = 0;       // body colour
    var cols = null;
    var ageBucket = -1;
    var outline = false; // drawn as an outline (see the outline section)
    var kbase = 1.0;     // outline size factor for this silhouette

    // FishBody: six segments 2..4 wide (2 + sin(pi i / 5) * 2, truncated)
    var segs = [2, 3, 3, 3, 3, 2];
    var segX = null;
    var segY = null;
    var gap = 0.78;

    // StarBody
    var starAngle = 0.0;
    var rotationSpeed = 0.0;

    // SnakeBody
    var snakeN = 0;
    var snX = null;
    var snY = null;

    // OctopusBody
    var octX = null;
    var octY = null;

    const EYE = 0x0A0A14;
    const TWO_PI = 6.283185;

    function initialize(speciesId, x, y, startAge, nowMs) {
        id = speciesId;
        sil = Species.SIL[id];
        kind = Species.MOTION[id];
        sc = Species.sizeScale(id);
        age = startAge;
        lastUpdateMs = nowMs;
        // 1 / lifespan in ms, varied by -100% .. +100% (CYD initializeAgingRate)
        var baseRate = 1.0 / (Cfg.LIFESPAN_DAYS * 24.0 * 60.0 * 60.0 * 1000.0);
        var variation = Cfg.LIFESPAN_VARIATION * (Rnd.below(200) / 100.0 - 1.0);
        agingRate = baseRate * (1.0 + variation);
        m = new Motion(kind, x, y);

        if (sil == Species.SIL_STAR) {
            rotationSpeed = Rnd.range(5, 10) / 1000.0;
            starAngle = Rnd.unit() * TWO_PI;
        } else if (sil == Species.SIL_SNAKE) {
            snakeN = Rnd.range(14, 28);
            snX = new [snakeN];
            snY = new [snakeN];
            for (var i = 0; i < snakeN; i++) {
                snX[i] = 0.0;
                snY[i] = 0.0;
            }
        } else if (sil == Species.SIL_OCTOPUS) {
            octX = new [8];
            octY = new [8];
            for (var t = 0; t < 8; t++) {
                octX[t] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
                octY[t] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
            }
        } else if (sil != Species.SIL_TURTLE && sil != Species.SIL_SHARK
                   && sil != Species.SIL_WHALE_SHARK && sil != Species.SIL_MANTA
                   && sil != Species.SIL_WHALE) {
            segX = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
            segY = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
        }
        ageSize = age;
        if (ageSize > 0.98) { ageSize = 0.98; }
        size = ageSize * Cfg.CREATURE_SCALE;

        if (sil == Species.SIL_CHROMIS_SHOAL) { outline = true; kbase = 1.1; }
        else if (sil == Species.SIL_FUSILIER) { outline = true; kbase = 1.0; }
        else if (sil == Species.SIL_ANTHIAS) { outline = true; kbase = 1.05; }
        else if (sil == Species.SIL_CARDINAL) { outline = true; kbase = 1.15; }
        else if (sil == Species.SIL_CLOWNFISH) { outline = true; kbase = 1.2; }
        else if (sil == Species.SIL_BLUE_TANG) { outline = true; kbase = 1.0; }
        else if (sil == Species.SIL_SHARK) { outline = true; kbase = 0.85; }
        else if (sil == Species.SIL_WHALE_SHARK) { outline = true; kbase = 1.0; }
        else if (sil == Species.SIL_WHALE) { outline = true; kbase = 1.0; }
        else if (sil == Species.SIL_MANTA) { outline = true; kbase = 1.0; }
        else if (sil == Species.SIL_TURTLE) { outline = true; kbase = 1.0; }
        refreshColours();
    }

    // ColorPalette::adjustColorByAgeAndHealth: every palette entry is drawn
    // at saturation 115 (health is always full here) and a value that fades
    // from 255 to 128 between adult and dead age. Only the hue is per species.
    function refreshColours() {
        var af = 1.0;
        if (age >= Cfg.AGE_ADULT) {
            af = 1.0 - ((age - Cfg.AGE_ADULT) / (Cfg.AGE_DEAD - Cfg.AGE_ADULT)) * 0.5;
        }
        var v = (255.0 * af).toNumber();
        if (v < 0) { v = 0; }
        if (v > 255) { v = 255; }
        // Outline colours for the big species are fixed (the CYD's whale
        // shark is near white, which would hide its spots), faded by age
        // the same way. So are the clownfish's orange and the blue tang's
        // blue, at full strength rather than saturation 115.
        if (sil == Species.SIL_CLOWNFISH) {
            col = Colour.scaled(0xFF6E0A, af);
        } else if (sil == Species.SIL_BLUE_TANG) {
            col = Colour.scaled(0x194BEB, af);
        } else if (sil == Species.SIL_SHARK) {
            col = Colour.scaled(0x969EAA, af);
        } else if (sil == Species.SIL_WHALE_SHARK) {
            col = Colour.scaled(0x60748C, af);
        } else if (sil == Species.SIL_WHALE) {
            col = Colour.scaled(0x3E547C, af);
        } else if (sil == Species.SIL_MANTA) {
            col = Colour.scaled(0x463C6E, af);
        } else if (sil == Species.SIL_TURTLE) {
            cols = [Colour.scaled(0x6E8C37, af), Colour.scaled(0x6E8C37, af * 0.6), Colour.scaled(0x96A55F, af)];
            col = cols[0];
        } else if (sil == Species.SIL_STAR) {
            cols = [Colour.hsv(240, 115, v), Colour.hsv(250, 115, v)];
            col = cols[0];
        } else if (sil == Species.SIL_SNAKE) {
            cols = [Colour.hsv(55, 115, v), Colour.hsv(70, 115, v)];   // spot, body
            col = cols[0];
        } else if (sil == Species.SIL_OCTOPUS) {
            cols = new [7];
            for (var i = 0; i < 7; i++) {
                cols[i] = Colour.hsv(210 + i * 2, 115, v);
            }
            col = cols[0];
        } else {
            col = Colour.hsv(Species.HUE[id], 115, v);
        }
    }

    function update(nowMs, dt) {
        if (plumpUntil != 0 && nowMs >= plumpUntil) {
            plumpScale = 1.0;
            plumpUntil = 0;
        }
        m.update(age, true, nowMs, dt);
        // updateAge: CO2 is always good, so age just advances with time
        age += (nowMs - lastUpdateMs) * agingRate;
        lastUpdateMs = nowMs;
        ageSize = age * plumpScale;
        if (ageSize > 0.98) { ageSize = 0.98; }
        if (ageSize < 0.0) { ageSize = 0.0; }
        size = ageSize * Cfg.CREATURE_SCALE;
        if (food != null) {
            if (food.offScreen) {
                food = null;
            } else {
                var fx = food.x - m.px;
                var fy = food.y - m.py;
                if (Math.sqrt(fx * fx + fy * fy) < 1.0) {
                    food.eat();
                    food = null;
                } else {
                    m.followFood(food.x, food.y);
                }
            }
        }
        if (age > 1.0) {
            age = 0.0;
        }
        var bucket = (age * 50.0).toNumber();
        if (bucket != ageBucket) {
            ageBucket = bucket;
            refreshColours();
        }
    }

    function x() { return m.px; }
    function y() { return m.py; }
    function isPokeable() { return age > Cfg.AGE_EGG && age < Cfg.AGE_DEAD; }
    function canTakeFood() {
        return food == null && age > Cfg.AGE_EGG && age < Cfg.AGE_SENIOR;
    }

    function scareFrom(x, y) { m.scareFrom(x, y); }
    function schoolToward(x, y) { m.schoolToward(x, y); }

    function setPlump(scale, nowMs, durationMs) {
        plumpScale = scale;
        plumpUntil = nowMs + durationMs;
    }

    // ---- drawing ------------------------------------------------------

    function draw(dc, nowMs, dt) {
        if (age < Cfg.AGE_EGG) {
            Gfx.px(dc, m.px, m.py, col);
            return;
        }
        if (sil == Species.SIL_CHROMIS_SHOAL) { outChromis(dc); }
        else if (sil == Species.SIL_FUSILIER) { outFusilier(dc); }
        else if (sil == Species.SIL_ANTHIAS) { outAnthias(dc); }
        else if (sil == Species.SIL_CARDINAL) { outCardinal(dc); }
        else if (sil == Species.SIL_SHARK) { outShark(dc); }
        else if (sil == Species.SIL_WHALE_SHARK) { outWhaleShark(dc); }
        else if (sil == Species.SIL_WHALE) { outWhale(dc); }
        else if (sil == Species.SIL_MANTA) { outManta(dc); }
        else if (sil == Species.SIL_TURTLE) { outTurtle(dc); }
        else if (sil == Species.SIL_BLUE_TANG) { outBlueTang(dc); }
        else if (sil == Species.SIL_YELLOW_TANG) { drawYellowTang(dc); }
        else if (sil == Species.SIL_MOORISH_IDOL) { drawMoorishIdol(dc); }
        else if (sil == Species.SIL_CLOWNFISH) { outClownfish(dc); }
        else if (sil == Species.SIL_SERGEANT) { drawSergeant(dc); }
        else if (sil == Species.SIL_SWEEPER) { drawSweeper(dc); }
        else if (sil == Species.SIL_DARTFISH) { drawDartfish(dc); }
        else if (sil == Species.SIL_SURGEON) { drawSurgeon(dc); }
        else if (sil == Species.SIL_UNICORN) { drawUnicorn(dc); }
        else if (sil == Species.SIL_STAR) { drawStar(dc, dt); }
        else if (sil == Species.SIL_SNAKE) { drawSnake(dc); }
        else if (sil == Species.SIL_OCTOPUS) { drawOctopus(dc, nowMs); }
        else { drawSilverside(dc); }   // Schooler and anything else
    }

    // ---- outline drawings ---------------------------------------------
    // Fish outlines for the families the CYD drew as chains of circles,
    // for the big species, and for the clownfish and blue tang, agreed
    // from mock-ups (30 Oct 2026). Local
    // coordinates: +x forward, +u up (the dorsal side), in tank units at
    // k = 1; k comes from kfac(). The dorsal side stays upward whichever
    // way the creature faces (mirrored when facing left), the way sprite
    // fish are flipped rather than rotated upside down. Corners are placed
    // at pixel precision (Gfx.polyF), not snapped to cells.

    function kfac() {
        return ageSize / 0.6 * kbase * Cfg.OUTLINE_SCALE;
    }

    // Rotate, mirror and move a list of [x, u] points into tank coordinates.
    function placePts(pts, k) {
        var cosA = Math.cos(m.angle);
        var sinA = Math.sin(m.angle);
        var flip = 1.0;
        if (cosA < 0.0) { flip = -1.0; }
        var n = pts.size();
        var out = new [n];
        for (var i = 0; i < n; i++) {
            var fx = pts[i][0] * k;
            var fu = pts[i][1] * k * flip;
            // forward = (cosA, sinA), up = (sinA, -cosA)
            out[i] = [m.px + cosA * fx + sinA * fu, m.py + sinA * fx - cosA * fu];
        }
        return out;
    }

    function shape(dc, pts, k, c) {
        Gfx.polyF(dc, placePts(pts, k), c);
    }

    function dotAt(dc, p, k, c) {
        var q = placePts([p], k);
        Gfx.px(dc, q[0][0], q[0][1], c);
    }

    function segAt(dc, p0, p1, k, c) {
        var q = placePts([p0, p1], k);
        Gfx.lineF(dc, q[0][0], q[0][1], q[1][0], q[1][1], c);
    }

    // deep damsel body, solid forked tail, dorsal and pectoral in a lighter tint
    function outChromis(dc) {
        var k = kfac();
        var c = col;
        var f = Colour.lighter(c, 0.5);
        shape(dc, [[3.8, 0.0], [2.6, 1.6], [0.6, 2.2], [-1.6, 1.9], [-3.2, 0.9], [-3.2, -0.9], [-1.6, -1.9], [0.6, -2.2], [2.6, -1.6]], k, c);
        shape(dc, [[-3.0, 0.9], [-6.2, 2.7], [-6.2, 1.1], [-4.6, 0.0], [-6.2, -1.1], [-6.2, -2.7], [-3.0, -0.9]], k, c);
        shape(dc, [[-2.0, 1.8], [1.4, 2.0], [0.2, 3.5], [-1.4, 3.3]], k, f);
        shape(dc, [[0.8, -0.6], [-0.9, -0.6], [-0.3, -2.4]], k, f);
        dotAt(dc, [2.4, 0.6], k, EYE);
        dotAt(dc, [3.0, 0.9], k, 0xF0F0FF);
    }

    // slim torpedo, deep solid fork, small dorsal, pale lateral band
    function outFusilier(dc) {
        var k = kfac();
        var c = col;
        var f = Colour.lighter(c, 0.5);
        shape(dc, [[5.4, 0.0], [3.6, 1.2], [0.0, 1.6], [-3.4, 1.2], [-4.8, 0.5], [-4.8, -0.5], [-3.4, -1.2], [0.0, -1.6], [3.6, -1.2]], k, c);
        shape(dc, [[-4.6, 0.6], [-7.8, 2.6], [-7.8, 1.0], [-6.2, 0.0], [-7.8, -1.0], [-7.8, -2.6], [-4.6, -0.6]], k, c);
        shape(dc, [[-1.4, 1.4], [1.4, 1.5], [0.6, 2.7], [-0.8, 2.6]], k, f);
        shape(dc, [[1.6, -0.5], [0.0, -0.5], [0.6, -1.9]], k, f);
        segAt(dc, [3.2, 0.1], [-3.4, 0.1], k, f);
        dotAt(dc, [4.0, 0.3], k, EYE);
        dotAt(dc, [4.6, 0.5], k, 0xF0F0FF);
    }

    // deep body, solid lyre tail, long dorsal with a streamer
    function outAnthias(dc) {
        var k = kfac();
        var c = col;
        var f = Colour.lighter(c, 0.5);
        shape(dc, [[3.4, 0.0], [2.2, 2.0], [0.0, 2.5], [-2.0, 2.0], [-3.2, 0.9], [-3.2, -0.9], [-2.0, -2.0], [0.0, -2.5], [2.2, -2.0]], k, c);
        shape(dc, [[-3.0, 1.0], [-6.6, 3.4], [-6.8, 1.6], [-4.8, 0.0], [-6.8, -1.6], [-6.6, -3.4], [-3.0, -1.0]], k, c);
        shape(dc, [[-2.4, 2.0], [1.8, 2.2], [1.4, 3.6], [-2.8, 3.6]], k, f);
        shape(dc, [[-2.8, 3.6], [-1.6, 3.6], [-4.0, 5.2]], k, f);
        shape(dc, [[0.8, -0.9], [-0.9, -0.9], [-0.4, -2.8]], k, f);
        dotAt(dc, [2.2, 0.8], k, EYE);
        dotAt(dc, [2.8, 1.1], k, 0xF0F0FF);
    }

    // compact rounded body, rounded tail, two small dorsals, big eye
    function outCardinal(dc) {
        var k = kfac();
        var c = col;
        var f = Colour.lighter(c, 0.5);
        shape(dc, [[3.0, 0.0], [2.2, 1.8], [0.0, 2.3], [-2.0, 1.8], [-3.0, 0.7], [-3.0, -0.7], [-2.0, -1.8], [0.0, -2.3], [2.2, -1.8]], k, c);
        shape(dc, [[-2.8, 1.0], [-4.6, 2.0], [-5.4, 0.9], [-5.4, -0.9], [-4.6, -2.0], [-2.8, -1.0]], k, c);
        shape(dc, [[-0.4, 2.1], [1.2, 2.1], [0.8, 3.4], [-0.6, 3.3]], k, f);
        shape(dc, [[-2.4, 1.7], [-1.0, 1.9], [-1.4, 3.0], [-2.6, 2.8]], k, f);
        shape(dc, [[0.8, -0.7], [-0.6, -0.7], [-0.1, -2.2]], k, f);
        var q = placePts([[1.6, 0.5]], k);
        Gfx.circle(dc, q[0][0], q[0][1], 0.7, EYE);
        dotAt(dc, [2.2, 0.9], k, 0xF0F0FF);
    }

    // clownfish: rounded orange body, rounded tail, notched dorsal, anal
    // and pelvic fins, three white bands (head, middle, tail base) edged in
    // black. Each band is the black shape with the white one drawn over it.
    function outClownfish(dc) {
        var k = kfac();
        var c = col;
        var white = 0xF5F5FA;
        shape(dc, [[-4.5, 0.7], [-5.5, 1.9], [-6.7, 2.5], [-7.7, 2.2], [-8.2, 1.2], [-8.3, 0.0], [-8.2, -1.2], [-7.7, -2.2], [-6.7, -2.5], [-5.5, -1.9], [-4.5, -0.7]], k, c);
        shape(dc, [[3.2, 2.4], [1.8, 3.7], [0.4, 2.9], [-0.6, 3.8], [-1.8, 4.2], [-2.9, 3.7], [-3.5, 2.6], [-3.9, 1.0], [-2.8, 1.6], [-1.3, 2.2], [0.6, 2.5], [2.6, 2.5]], k, c);
        shape(dc, [[-0.4, -2.2], [-1.0, -3.4], [-2.0, -3.9], [-3.0, -3.5], [-3.6, -2.2], [-3.8, -0.9], [-2.8, -1.5], [-1.3, -2.1]], k, c);
        shape(dc, [[2.8, -2.1], [2.3, -3.4], [1.4, -3.7], [1.0, -2.3]], k, c);
        shape(dc, [[6.3, 0.2], [6.0, 1.0], [5.3, 1.8], [4.2, 2.3], [2.6, 2.5], [0.6, 2.5], [-1.3, 2.2], [-2.8, 1.6], [-3.8, 1.0], [-4.7, 0.8], [-4.7, -0.8], [-3.8, -0.9], [-2.8, -1.5], [-1.3, -2.1], [0.4, -2.3], [2.4, -2.2], [4.2, -1.8], [5.4, -1.2], [6.1, -0.5]], k, c);
        shape(dc, [[2.5, 2.5], [2.6, 2.5], [4.2, 2.3], [4.3, 2.25], [3.9, 1.0], [3.8, 0.0], [3.9, -1.0], [4.2, -1.8], [2.4, -2.2], [2.1, -1.0], [2.0, 0.0], [2.1, 1.0]], k, EYE);
        shape(dc, [[2.9, 2.46], [3.9, 2.34], [3.5, 1.0], [3.4, 0.0], [3.5, -1.0], [3.8, -1.89], [2.8, -2.11], [2.5, -1.0], [2.4, 0.0], [2.5, 1.0]], k, white);
        shape(dc, [[-1.0, 2.25], [0.6, 2.5], [0.9, 2.5], [1.2, 1.2], [1.8, 0.2], [1.2, -0.9], [0.8, -2.28], [0.4, -2.3], [-1.0, -2.14], [-1.2, -0.6], [-1.2, 0.8]], k, EYE);
        shape(dc, [[-0.6, 2.31], [0.5, 2.48], [0.8, 1.2], [1.4, 0.2], [0.8, -0.9], [0.4, -2.3], [-0.6, -2.18], [-0.8, -0.6], [-0.8, 0.8]], k, white);
        shape(dc, [[-4.4, 0.87], [-3.8, 1.0], [-2.8, 1.6], [-2.8, -1.5], [-3.8, -0.9], [-4.4, -0.83]], k, EYE);
        shape(dc, [[-4.0, 0.96], [-3.8, 1.0], [-3.2, 1.36], [-3.2, -1.26], [-3.8, -0.9], [-4.0, -0.88]], k, white);
        var q = placePts([[4.85, 0.7]], k);
        Gfx.circle(dc, q[0][0], q[0][1], 0.5, EYE);
        dotAt(dc, [5.3, 1.05], k, 0xF0F0FF);
    }

    // blue tang: deep oval body with long dorsal and anal fins, yellow
    // forked tail and pectoral, and the black marking that runs from the
    // eye along the upper body to the tail, enclosing a blue patch
    function outBlueTang(dc) {
        var k = kfac();
        var c = col;
        var yellow = 0xFFDC28;
        shape(dc, [[4.4, 2.9], [2.4, 4.1], [0.0, 4.4], [-2.4, 4.0], [-4.4, 3.0], [-5.6, 1.7], [-5.3, 1.4], [-4.0, 2.4], [-2.2, 3.2], [0.0, 3.6], [2.2, 3.5]], k, c);
        shape(dc, [[1.4, -3.2], [-0.6, -4.1], [-2.8, -3.9], [-4.6, -2.6], [-5.6, -1.4], [-5.0, -1.3], [-3.6, -2.3], [-1.8, -3.0]], k, c);
        shape(dc, [[4.2, -2.4], [3.4, -3.6], [2.6, -3.8], [2.8, -2.8]], k, c);
        shape(dc, [[7.0, 0.3], [6.6, 1.0], [5.7, 2.1], [4.2, 3.0], [2.2, 3.5], [0.0, 3.6], [-2.2, 3.2], [-4.0, 2.4], [-5.3, 1.4], [-6.1, 0.8], [-6.1, -0.8], [-5.0, -1.3], [-3.6, -2.3], [-1.8, -3.0], [0.4, -3.3], [2.6, -3.0], [4.6, -2.3], [6.0, -1.2], [6.8, -0.4]], k, c);
        shape(dc, [[-5.4, 0.7], [-8.4, 2.7], [-9.2, 2.5], [-8.7, 0.0], [-9.2, -2.5], [-8.4, -2.7], [-5.4, -0.7]], k, yellow);
        shape(dc, [[6.2, 1.2], [5.4, 2.4], [3.8, 3.1], [1.8, 3.35], [-0.4, 3.35], [-2.6, 2.95], [-4.4, 2.1], [-5.6, 1.0], [-5.9, 0.2], [-5.5, -0.4], [-4.0, -0.9], [-2.0, -1.1], [0.0, -0.9], [1.6, -0.4], [2.6, 0.6], [4.0, 0.9], [5.0, 0.4]], k, EYE);
        shape(dc, [[0.9, 1.15], [0.68, 1.45], [0.07, 1.7], [-0.81, 1.83], [-1.79, 1.83], [-2.67, 1.7], [-3.28, 1.45], [-3.5, 1.15], [-3.28, 0.85], [-2.67, 0.6], [-1.79, 0.47], [-0.81, 0.47], [0.07, 0.6], [0.68, 0.85]], k, c);
        shape(dc, [[4.0, -0.4], [2.0, -1.0], [0.6, -2.2], [1.4, -2.6], [3.0, -1.8]], k, yellow);
        dotAt(dc, [5.4, 1.3], k, 0xF0F0FF);
    }

    // reef shark: pointed snout, tall first dorsal, pectoral, second
    // dorsal, tail with the upper lobe larger, fin tips black (blacktip)
    // or white (whitetip), gill marks, pale belly
    function outShark(dc) {
        var k = kfac();
        var c = col;
        var f = Colour.lighter(c, 0.35);
        var tip = 0x14161E;
        if (id == Species.ID_WHITETIP_REEF_SHARK) {
            tip = 0xF0F0F5;
        }
        shape(dc, [[10.0, 0.0], [7.0, 1.6], [3.0, 2.4], [-2.0, 2.2], [-6.0, 1.4], [-8.0, 0.7], [-8.0, -0.7], [-6.0, -1.4], [-2.0, -2.0], [3.0, -2.2], [7.0, -1.5]], k, c);
        shape(dc, [[7.0, -1.5], [3.0, -2.2], [-2.0, -2.0], [-6.0, -1.4], [-6.0, -0.4], [-2.0, -0.6], [3.0, -0.8]], k, f);
        shape(dc, [[-1.0, 2.1], [3.0, 2.3], [1.2, 5.4]], k, c);
        shape(dc, [[1.2, 5.4], [1.9, 4.3], [0.4, 4.2]], k, tip);
        shape(dc, [[-5.5, 1.3], [-3.8, 1.5], [-4.8, 2.7]], k, c);
        shape(dc, [[3.0, -1.9], [5.2, -2.0], [1.4, -4.8]], k, c);
        shape(dc, [[1.4, -4.8], [2.4, -4.0], [1.0, -3.8]], k, tip);
        shape(dc, [[-7.5, 0.8], [-11.6, 4.4], [-11.8, 2.9], [-9.6, 0.0], [-11.0, -2.3], [-10.8, -3.1], [-7.5, -0.8]], k, c);
        dotAt(dc, [8.0, 0.4], k, EYE);
        dotAt(dc, [5.2, -0.4], k, 0x14161E);
        dotAt(dc, [4.4, -0.4], k, 0x14161E);
        dotAt(dc, [3.6, -0.4], k, 0x14161E);
    }

    // whale shark: broad flat head, wide body, sweeping dorsal, big
    // crescent tail, white spots in rows along the back
    function outWhaleShark(dc) {
        var k = kfac();
        var c = col;
        var f = Colour.lighter(c, 0.35);
        var sp = 0xEBF0F5;
        shape(dc, [[11.5, 0.9], [11.5, -0.9], [9.0, -2.6], [3.0, -3.4], [-4.0, -3.0], [-8.0, -1.8], [-10.0, -0.8], [-10.0, 0.8], [-8.0, 1.8], [-4.0, 3.0], [3.0, 3.4], [9.0, 2.6]], k, c);
        shape(dc, [[9.0, -2.6], [3.0, -3.4], [-4.0, -3.0], [-8.0, -1.8], [-8.0, -0.6], [-4.0, -1.2], [3.0, -1.4], [9.0, -1.0]], k, f);
        shape(dc, [[-3.5, 3.0], [1.5, 3.3], [-1.0, 6.2]], k, c);
        shape(dc, [[3.5, -2.9], [7.0, -3.1], [2.5, -6.4]], k, c);
        shape(dc, [[-9.5, 1.0], [-13.6, 5.2], [-13.9, 3.2], [-11.6, 0.0], [-13.7, -3.6], [-13.1, -4.9], [-9.5, -1.0]], k, c);
        for (var i = 0; i < 8; i++) {
            var sx = 8.5 - i * 2.3;
            dotAt(dc, [sx, 1.0 + (i % 2) * 1.2], k, sp);
            if (i % 2 == 0) {
                dotAt(dc, [sx - 1.1, 2.4], k, sp);
            }
        }
        dotAt(dc, [9.6, -0.6], k, EYE);
    }

    // humpback: long body, small dorsal hump, very long pectoral flipper,
    // grooved pale throat, broad fluke, blowhole
    function outWhale(dc) {
        var k = kfac();
        var c = col;
        var f = Colour.lighter(c, 0.4);
        shape(dc, [[12.5, 0.4], [12.5, -0.8], [9.0, -2.4], [2.0, -3.0], [-5.0, -2.6], [-9.0, -1.6], [-11.0, -0.6], [-11.0, 0.6], [-9.0, 1.4], [-5.0, 2.2], [1.0, 2.6], [8.0, 2.0]], k, c);
        shape(dc, [[10.0, -1.8], [2.0, -3.0], [-5.0, -2.6], [-5.0, -1.4], [2.0, -1.6], [10.0, -0.9]], k, f);
        shape(dc, [[-4.0, 2.1], [-1.0, 2.5], [-2.6, 3.7]], k, c);
        shape(dc, [[4.5, -2.3], [6.8, -2.6], [-1.0, -6.8], [-2.6, -5.6]], k, f);
        shape(dc, [[-10.5, 0.6], [-14.2, 3.9], [-14.6, 2.6], [-12.6, 0.0], [-14.6, -2.6], [-14.2, -3.9], [-10.5, -0.6]], k, c);
        dotAt(dc, [9.8, -0.9], k, EYE);
        dotAt(dc, [7.0, 1.9], k, 0x14141E);
    }

    // manta from above: swept diamond wings, two cephalic lobes forward,
    // long thin tail, lighter shoulder patches, eyes at the sides
    function outManta(dc) {
        var k = kfac();
        var c = col;
        var f = Colour.lighter(c, 0.45);
        shape(dc, [[4.5, 1.2], [1.5, 9.4], [-0.6, 9.2], [-4.0, 1.7], [-4.0, -1.7], [-0.6, -9.2], [1.5, -9.4], [4.5, -1.2]], k, c);
        shape(dc, [[4.5, 1.2], [5.0, 1.0], [5.0, -1.0], [4.5, -1.2], [3.0, -1.4], [3.0, 1.4]], k, c);
        shape(dc, [[5.0, 1.0], [7.0, 1.6], [7.4, 0.9], [5.0, 0.3]], k, c);
        shape(dc, [[5.0, -1.0], [7.0, -1.6], [7.4, -0.9], [5.0, -0.3]], k, c);
        shape(dc, [[2.6, 1.6], [0.2, 5.4], [-1.6, 2.2]], k, f);
        shape(dc, [[2.6, -1.6], [0.2, -5.4], [-1.6, -2.2]], k, f);
        segAt(dc, [-4.0, 0.0], [-11.5, 0.0], k, c);
        dotAt(dc, [4.6, 1.5], k, 0x14161E);
        dotAt(dc, [4.6, -1.5], k, 0x14161E);
    }

    // turtle from above: oval shell with a darker scute row, head with two
    // eyes, long swept front flippers, short rear flippers, stub tail
    function outTurtle(dc) {
        var k = kfac();
        var c = cols[0];
        var d = cols[1];
        var lm = cols[2];
        shape(dc, [[2.8, 2.4], [3.6, 3.3], [-0.6, 7.2], [-1.8, 6.2], [0.4, 3.1]], k, lm);
        shape(dc, [[2.8, -2.4], [3.6, -3.3], [-0.6, -7.2], [-1.8, -6.2], [0.4, -3.1]], k, lm);
        shape(dc, [[-3.0, 2.4], [-2.2, 3.2], [-5.2, 4.8], [-5.6, 3.7]], k, lm);
        shape(dc, [[-3.0, -2.4], [-2.2, -3.2], [-5.2, -4.8], [-5.6, -3.7]], k, lm);
        shape(dc, [[-4.3, 0.6], [-6.0, 0.0], [-4.3, -0.6]], k, lm);
        shape(dc, [[4.0, 1.0], [6.6, 1.2], [7.5, 0.0], [6.6, -1.2], [4.0, -1.0]], k, lm);
        shape(dc, [[4.2, 0.0], [3.2, 2.7], [0.0, 3.6], [-3.0, 3.0], [-4.6, 1.1], [-4.6, -1.1], [-3.0, -3.0], [0.0, -3.6], [3.2, -2.7]], k, c);
        shape(dc, [[2.7, 0.0], [1.6, 1.5], [-1.4, 1.5], [-2.8, 0.0], [-1.4, -1.5], [1.6, -1.5]], k, d);
        shape(dc, [[1.0, 1.8], [-1.0, 1.8], [-1.8, 2.8], [0.6, 2.9]], k, d);
        shape(dc, [[1.0, -1.8], [-1.0, -1.8], [-1.8, -2.8], [0.6, -2.9]], k, d);
        dotAt(dc, [6.6, 0.9], k, EYE);
        dotAt(dc, [6.6, -0.9], k, EYE);
    }

    // -- FishBody helpers --

    function placeSegments(cosA, sinA) {
        segX[0] = m.px;
        segY[0] = m.py;
        for (var i = 1; i < 6; i++) {
            var w = segs[i - 1];
            if (segs[i] > w) { w = segs[i]; }
            var step = w * size * gap * sc;
            segX[i] = segX[i - 1] - cosA * step;
            segY[i] = segY[i - 1] - sinA * step;
        }
    }

    function drawOvalBody(dc, c, fat, cosA, sinA) {
        placeSegments(cosA, sinA);
        for (var i = 0; i < 6; i++) {
            var t = i / 5.0;
            var r = segs[i] * size * sc * fat * (0.7 + 0.3 * Math.sin(t * Math.PI));
            if (r < 1.0) { r = 1.0; }
            Gfx.circle(dc, segX[i], segY[i], r, c);
        }
    }

    function drawForkedTail(dc, c, spread, length, cosA, sinA) {
        var tx = segX[5];
        var ty = segY[5];
        var bx = tx - cosA * size * length * sc;
        var by = ty - sinA * size * length * sc;
        var ux = -sinA * size * spread * sc;
        var uy = cosA * size * spread * sc;
        Gfx.line(dc, tx, ty, bx + ux, by + uy, c);
        Gfx.line(dc, tx, ty, bx - ux, by - uy, c);
    }

    function drawEye(dc, ex, ey) {
        Gfx.px(dc, ex, ey, EYE);
    }

    function drawSergeant(dc) {
        var cosA = Math.cos(m.angle);
        var sinA = Math.sin(m.angle);
        var bar = 0x14141E;
        gap = 0.7;
        drawOvalBody(dc, col, 1.0, cosA, sinA);
        drawForkedTail(dc, col, 1.8, 2.0, cosA, sinA);
        for (var b = 1; b <= 3; b++) {
            var idx = b + 1;
            if (idx > 5) { idx = 5; }
            Gfx.line(dc, segX[idx] - sinA * size * 1.6 * sc, segY[idx] + cosA * size * 1.6 * sc,
                     segX[idx] + sinA * size * 1.6 * sc, segY[idx] - cosA * size * 1.6 * sc, bar);
        }
        drawEye(dc, m.px + cosA * size * 1.1 * sc, m.py + sinA * size * 1.1 * sc);
    }

    function drawSweeper(dc) {
        var cosA = Math.cos(m.angle);
        var sinA = Math.sin(m.angle);
        gap = 0.6;
        drawOvalBody(dc, col, 1.2, cosA, sinA);
        var tx = segX[5];
        var ty = segY[5];
        Gfx.tri(dc, tx, ty, tx - cosA * size * 2.2 * sc, ty - sinA * size * 2.2 * sc,
                tx - sinA * size * 1.2 * sc, ty + cosA * size * 1.2 * sc, col);
        drawEye(dc, m.px + cosA * size * 1.0 * sc, m.py + sinA * size * 1.0 * sc);
    }

    function drawSilverside(dc) {
        var cosA = Math.cos(m.angle);
        var sinA = Math.sin(m.angle);
        gap = 1.15;
        drawOvalBody(dc, col, 0.45, cosA, sinA);
        drawForkedTail(dc, col, 1.4, 2.6, cosA, sinA);
        drawEye(dc, m.px + cosA * size * 1.4 * sc, m.py + sinA * size * 1.4 * sc);
    }

    function drawDartfish(dc) {
        var cosA = Math.cos(m.angle);
        var sinA = Math.sin(m.angle);
        var tip = 0xF5F5FA;
        gap = 1.2;
        drawOvalBody(dc, col, 0.4, cosA, sinA);
        var tx = segX[5];
        var ty = segY[5];
        var r = size * sc;
        if (r < 1.0) { r = 1.0; }
        Gfx.circle(dc, tx - cosA * size * 1.5 * sc, ty - sinA * size * 1.5 * sc, r, tip);
        drawEye(dc, m.px + cosA * size * 1.5 * sc, m.py + sinA * size * 1.5 * sc);
    }

    function drawSurgeon(dc) {
        var cosA = Math.cos(m.angle);
        var sinA = Math.sin(m.angle);
        var spine = 0xDCDCE6;
        var rad = 3.2 * size * sc;
        if (rad < 2.0) { rad = 2.0; }
        Gfx.circle(dc, m.px, m.py, rad, col);
        // tail: back * 1.35, sides * 0.85
        Gfx.tri(dc, m.px - cosA * rad * 1.35, m.py - sinA * rad * 1.35,
                m.px - sinA * rad * 0.85, m.py + cosA * rad * 0.85,
                m.px + sinA * rad * 0.85, m.py - cosA * rad * 0.85, col);
        Gfx.px(dc, m.px - cosA * rad * 0.7, m.py - sinA * rad * 0.7, spine);
        drawEye(dc, m.px + cosA * rad * 0.5, m.py + sinA * rad * 0.5);
    }

    function drawUnicorn(dc) {
        var cosA = Math.cos(m.angle);
        var sinA = Math.sin(m.angle);
        gap = 0.85;
        drawOvalBody(dc, col, 0.95, cosA, sinA);
        drawForkedTail(dc, col, 1.6, 2.4, cosA, sinA);
        var r = size * 0.9 * sc;
        if (r < 1.0) { r = 1.0; }
        Gfx.circle(dc, m.px + cosA * size * 2.0 * sc, m.py + sinA * size * 2.0 * sc, r, col);
        drawEye(dc, m.px + cosA * size * 1.2 * sc, m.py + sinA * size * 1.2 * sc);
    }

    function drawYellowTang(dc) {
        var cosA = Math.cos(m.angle);
        var sinA = Math.sin(m.angle);
        var rad = 3.2 * size * sc;
        if (rad < 2.0) { rad = 2.0; }
        Gfx.circle(dc, m.px, m.py, rad, col);
        // nose: forward 1.35, flanks at +/- 0.7 rad, 0.55
        Gfx.tri(dc, m.px + cosA * rad * 1.35, m.py + sinA * rad * 1.35,
                m.px + Math.cos(m.angle + 0.7) * rad * 0.55, m.py + Math.sin(m.angle + 0.7) * rad * 0.55,
                m.px + Math.cos(m.angle - 0.7) * rad * 0.55, m.py + Math.sin(m.angle - 0.7) * rad * 0.55, col);
        Gfx.tri(dc, m.px - cosA * rad * 1.3, m.py - sinA * rad * 1.3,
                m.px - sinA * rad * 0.8, m.py + cosA * rad * 0.8,
                m.px + sinA * rad * 0.8, m.py - cosA * rad * 0.8, col);
        drawEye(dc, m.px + cosA * rad * 0.4, m.py + sinA * rad * 0.4);
    }

    function drawMoorishIdol(dc) {
        var cosA = Math.cos(m.angle);
        var sinA = Math.sin(m.angle);
        var black = 0x0F0F19;
        var white = 0xF5F5FA;
        var yellow = 0xFFD228;
        var rad = 2.8 * size * sc;
        if (rad < 2.0) { rad = 2.0; }
        Gfx.circleArray(dc, m.px, m.py, rad * 0.55, rad * 1.35, m.angle + Math.PI / 2.0, white);
        Gfx.circle(dc, m.px + cosA * rad * 0.35, m.py + sinA * rad * 0.35, rad * 0.55, yellow);
        Gfx.circle(dc, m.px - cosA * rad * 0.2, m.py - sinA * rad * 0.2, rad * 0.7, black);
        // dorsal streamer: angle - pi/2 is (sinA, -cosA)
        Gfx.line(dc, m.px, m.py, m.px + sinA * rad * 2.0, m.py - cosA * rad * 2.0, white);
        drawEye(dc, m.px + cosA * rad * 0.5, m.py + sinA * rad * 0.5);
    }

    // -- StarBody --

    function drawStar(dc, dt) {
        var vm = m.physSpeed();
        if (vm < 0.1) { vm = 0.1; }
        starAngle += vm * rotationSpeed * dt;
        while (starAngle >= TWO_PI) { starAngle -= TWO_PI; }
        while (starAngle < 0.0) { starAngle += TWO_PI; }
        var pink = cols[0];
        var tip = cols[1];
        var armLen = 5.0 * size;
        var armRad = 2.0 * size;
        if (armRad < 1.0) { armRad = 1.0; }
        var tipR = (armRad * 0.55).toNumber();
        if (tipR < 1) { tipR = 1; }
        for (var i = 0; i < 5; i++) {
            var a = starAngle + (TWO_PI / 5.0) * i;
            var tx = m.px + Math.cos(a) * armLen;
            var ty = m.py + Math.sin(a) * armLen;
            var lx = m.px + Math.cos(a - Math.PI / 5.0) * armRad;
            var ly = m.py + Math.sin(a - Math.PI / 5.0) * armRad;
            var rx = m.px + Math.cos(a + Math.PI / 5.0) * armRad;
            var ry = m.py + Math.sin(a + Math.PI / 5.0) * armRad;
            Gfx.tri(dc, tx, ty, lx, ly, rx, ry, pink);
            Gfx.circle(dc, tx, ty, tipR, tip);
        }
        var cr = (armRad * 0.7).toNumber();
        if (cr < 1) { cr = 1; }
        Gfx.circle(dc, m.px, m.py, cr, pink);
    }

    // -- SnakeBody --

    function snakeSegment(dc, i, vinX, vinY, c, thickness) {
        var dvx = vinX - snX[i];
        var dvy = vinY - snY[i];
        var a = Math.atan2(dvy, dvx);
        var step = thickness * 0.85;
        if (step < 1.0) { step = 1.0; }
        snX[i] = vinX - Math.cos(a) * step;
        snY[i] = vinY - Math.sin(a) * step;
        var rad = thickness.toNumber();
        if (rad < 1) { rad = 1; }
        Gfx.circle(dc, snX[i], snY[i], rad, c);
    }

    function snakeColour(i) {
        if (i % 3 == 0) {
            return cols[0];
        }
        return cols[1];
    }

    function drawSnake(dc) {
        var cosA = Math.cos(m.angle);
        var sinA = Math.sin(m.angle);
        var visible = ((snakeN - 1) * size).toNumber();
        if (visible < 4) { visible = 4; }
        if (visible > snakeN - 1) { visible = snakeN - 1; }
        var headThick = 2.2 * size;
        if (headThick < 1.4) { headThick = 1.4; }
        var denom = visible - 1;
        if (denom < 1) { denom = 1; }
        for (var i = visible - 1; i > -1; i--) {
            var t = i.toFloat() / denom;
            var thickness = headThick * (1.0 - t * 0.65);
            snakeSegment(dc, i + 1, snX[i], snY[i], snakeColour(i), thickness);
        }
        snakeSegment(dc, 0, m.px, m.py, cols[0], headThick);
        var hr = (headThick + 0.5).toNumber();
        if (hr < 1) { hr = 1; }
        Gfx.circle(dc, m.px, m.py, hr, cols[0]);
        Gfx.px(dc, m.px + cosA * headThick * 0.4, m.py + sinA * headThick * 0.4, EYE);
    }

    // -- OctopusBody --

    function drawTentacle(dc, i, nowMs, cosA, sinA) {
        var rearSpread = Math.PI * 0.95;
        var bcx = m.px - cosA * (14.0 * size / 6.0);
        var bcy = m.py - sinA * (14.0 * size / 6.0);
        var ta = m.angle + Math.PI + (i - 3.5) * (rearSpread / 7.0);
        var curX = bcx + Math.cos(ta) * (14.0 * size / 7.0);
        var curY = bcy + Math.sin(ta) * (14.0 * size / 7.0);
        var segLen = (14.0 * size * 0.75) / 6.0;
        var time = nowMs / 1000.0;
        var vf = m.physSpeed() / 2.0;
        if (vf > 1.0) { vf = 1.0; }
        var sx = octX[i];
        var sy = octY[i];
        for (var j = 0; j < 6; j++) {
            var dvx = curX - sx[j];
            var dvy = curY - sy[j];
            var a = Math.atan2(dvy, dvx) + Math.sin(time * 2.0 + i * 0.5 + j * 0.3) * 0.2 * vf;
            sx[j] = curX - Math.cos(a) * segLen;
            sy[j] = curY - Math.sin(a) * segLen;
            Gfx.line(dc, curX, curY, sx[j], sy[j], cols[j + 1]);
            curX = sx[j];
            curY = sy[j];
        }
    }

    function drawOctopus(dc, nowMs) {
        var cosA = Math.cos(m.angle);
        var sinA = Math.sin(m.angle);
        var rad2 = (14.0 * size / 4.0).toNumber();
        if (rad2 < 2) { rad2 = 2; }
        var len2 = (14.0 * size / 2.0).toNumber();
        if (len2 < 3) { len2 = 3; }
        for (var i = 0; i < 8; i++) {
            drawTentacle(dc, i, nowMs, cosA, sinA);
        }
        Gfx.circle(dc, m.px, m.py, rad2, cols[0]);
        Gfx.circleArray(dc, m.px, m.py, rad2 / 2, len2, m.angle, cols[0]);
    }
}
