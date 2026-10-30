using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

// Port of lib/Aquarium/Aquarium.h (the esp32-2432s028r build: autonomous
// feeding, curated boot population, creatures kept on screen, fixed
// environment). The tank is the circle of radius Cfg.R centred on Cfg.C.
// step() advances everything one frame; draw() paints it.
class Tank {
    var creatures = [];
    var plants = [];
    var foods = [];
    var boids;
    var dt;
    var bootMs;
    var pelletsEaten = 0;

    var bubbleText = null;
    var bubbleUntil = 0;
    var diaryText = null;
    var diaryUntil = 0;

    var lastFoodMs = 0;
    var nextFoodDelay = 0;
    var nextRefillMs = 0;

    // visitors: 0 none, 1 cat paw, 2 duck, 3 diver, 4 shadow
    var visitor = 0;
    var visitorStart = 0;
    var visitorEnd = 0;
    var nextVisitorMs = 0;
    var vX = 0.0;
    var vY = 0.0;
    var vSpeed = 0.0;

    var weekend = false;
    var lastDayCheck = 0;

    function initialize() {
        var now = System.getTimer();
        bootMs = now;
        dt = Cfg.dt();
        boids = new Boids();
        discover(Species.ID_CHROMIS, now);
        // three plants rooted just below the lower arc, like the CYD's row
        // just below its bottom edge: an anemone and two kelp
        for (var i = 0; i < Cfg.NUM_PLANTS; i++) {
            var a = (70.0 + 20.0 * i) * Math.PI / 180.0;
            var rr = Cfg.R + 7.0;
            var sp = Species.ID_KELP;
            if (i == 0) {
                sp = Species.ID_ANEMONE;
            }
            plants.add(new Plant(Cfg.C + Math.cos(a) * rr, Cfg.C + Math.sin(a) * rr, sp));
            discover(sp, now);
        }
        // curated boot population: NUM_FISH distinct weighted species
        var used = new [Species.COUNT];
        for (var k = 0; k < Species.COUNT; k++) {
            used[k] = false;
        }
        for (var n = 0; n < Cfg.NUM_FISH; n++) {
            var id = Species.pickWeightedSwimmer(used);
            used[id] = true;
            spawnAt(n, id, now);
        }
        scheduleNextRefill(now);
        scheduleNextFood(true, now);
        scheduleNextVisitor(true, now);
        checkDay(now);
    }

    // ---- population ---------------------------------------------------

    // CYD initialCreatureAge with CYD_CURATED_BOOT_POPULATION
    function initialAge(index) {
        if (index == 0) {
            return Rnd.range(74, 84) / 100.0;
        }
        if (index == 1) {
            return Rnd.range(66, 78) / 100.0;
        }
        return Rnd.range(52, 69) / 100.0;
    }

    function spawnAt(index, id, now) {
        var a = Rnd.unit() * 6.283185;
        var r = Rnd.unit() * (Cfg.KEEP_R - 8.0);
        creatures.add(new Creature(id, Cfg.C + Math.cos(a) * r, Cfg.C + Math.sin(a) * r,
                                   initialAge(index), now));
        discover(id, now);
    }

    function nextRosterSpecies() {
        var used = new [Species.COUNT];
        for (var i = 0; i < Species.COUNT; i++) {
            used[i] = false;
        }
        for (var k = 0; k < creatures.size(); k++) {
            used[creatures[k].id] = true;
        }
        return Species.pickWeightedSwimmer(used);
    }

    function scheduleNextRefill(now) {
        nextRefillMs = now + Rnd.range(Cfg.REFILL_MIN_MS, Cfg.REFILL_MAX_MS + 1);
    }

    // ---- discovery and overlays --------------------------------------

    function discover(id, now) {
        if (gGuide.discover(id)) {
            bubbleText = "NEW " + Species.NAME[id];
            bubbleUntil = now + 2200;
        }
    }

    function bubble(now) {
        if (bubbleText != null && now < bubbleUntil) {
            return bubbleText;
        }
        return null;
    }

    function showDiary(now) {
        var hours = (now - bootMs) / 3600000;
        diaryText = "" + hours + "H  " + creatures.size() + " ALIVE  " + pelletsEaten + " EAT";
        diaryUntil = now + 8000;
    }

    function diary(now) {
        if (diaryText != null && now < diaryUntil) {
            return diaryText;
        }
        return null;
    }

    // ---- food ----------------------------------------------------------

    function addFood(x, now) {
        var f = new Food(x);
        foods.add(f);
        discover(Species.ID_FISH_FLAKE, now);
        var best = null;
        var bestD = 1.0e9;
        for (var i = 0; i < creatures.size(); i++) {
            var c = creatures[i];
            if (!c.canTakeFood()) { continue; }
            var dx = c.x() - f.x;
            var dy = c.y() - f.y;
            var d = dx * dx + dy * dy;
            if (d < bestD) {
                bestD = d;
                best = c;
            }
        }
        if (best != null) {
            best.food = f;
        }
    }

    function activeFoodCount() {
        var n = 0;
        for (var i = 0; i < foods.size(); i++) {
            var f = foods[i];
            if (!f.offScreen && !f.eaten) {
                n++;
            }
        }
        return n;
    }

    function scheduleNextFood(bootWindow, now) {
        lastFoodMs = now;
        var minD = Cfg.FOOD_MIN_MS;
        var maxD = Cfg.FOOD_MAX_MS;
        if (bootWindow) {
            minD = Cfg.FOOD_BOOT_MIN_MS;
            maxD = Cfg.FOOD_BOOT_MAX_MS;
        } else if (weekend) {
            minD = (minD * 2) / 3;
            maxD = (maxD * 2) / 3;
        }
        nextFoodDelay = Rnd.range(minD, maxD + 1);
    }

    function handleAutonomousLife(now) {
        if (nextFoodDelay == 0) {
            scheduleNextFood(true, now);
        }
        if (now - lastFoodMs < nextFoodDelay) {
            return;
        }
        if (activeFoodCount() < Cfg.MAX_FOOD) {
            addFood(Cfg.C + Rnd.range(-30, 31), now);
        }
        scheduleNextFood(false, now);
    }

    // tap: drop a pellet at tank x
    function dropPellet(x, now) {
        addFood(x, now);
    }

    // ---- visitors ------------------------------------------------------

    function scheduleNextVisitor(first, now) {
        if (first) {
            nextVisitorMs = now + Rnd.range(240000, 480001);        // 4 .. 8 min
        } else {
            nextVisitorMs = now + Rnd.range(2700000, 4500001);      // 45 .. 75 min
        }
    }

    function startVisitor(now) {
        var kind = Rnd.below(4);
        visitorStart = now;
        vX = 0.0;
        vY = 0.0;
        vSpeed = 0.0;
        if (kind == 0) {
            visitor = 1;    // cat paw at the top edge
            vX = Rnd.range(10, 70).toFloat();
            var dx = vX - Cfg.C;
            vY = Cfg.C - Math.sqrt(Cfg.R * Cfg.R - dx * dx);
            visitorEnd = now + 2000;
        } else if (kind == 1) {
            visitor = 2;    // duck crossing at y 18
            vY = 18.0;
            vX = Cfg.C - Math.sqrt(Cfg.R * Cfg.R - 22.0 * 22.0) - 4.0;
            vSpeed = 0.35;
            visitorEnd = now + 6000;
        } else if (kind == 2) {
            visitor = 3;    // diver sinking down one side
            vX = 14.0;
            if (Rnd.below(2) == 1) {
                vX = 66.0;
            }
            vY = 12.0;
            vSpeed = 0.22;
            visitorEnd = now + 8000;
        } else {
            visitor = 4;    // shadow sweeping across the middle
            vX = -8.0;
            vY = Cfg.C;
            vSpeed = 0.55;
            visitorEnd = now + 3500;
        }
    }

    function scareNear(sx, sy, radius) {
        for (var i = 0; i < creatures.size(); i++) {
            var c = creatures[i];
            var dx = c.x() - sx;
            var dy = c.y() - sy;
            if (Math.sqrt(dx * dx + dy * dy) <= radius) {
                c.scareFrom(sx, sy);
            }
        }
        boids.scareFrom(sx, sy, radius);
    }

    function updateVisitors(now) {
        if (visitor == 0) {
            if (now >= nextVisitorMs) {
                startVisitor(now);
            }
            return;
        }
        if (now >= visitorEnd) {
            visitor = 0;
            scheduleNextVisitor(false, now);
            return;
        }
        var elapsed = now - visitorStart;
        if (visitor == 1) {
            if (elapsed < 200) {
                scareNear(vX, vY + 8.0, 18.0);
            }
        } else if (visitor == 2) {
            vX += vSpeed * dt;
        } else if (visitor == 3) {
            vY += vSpeed * dt;
        } else {
            vX += vSpeed * dt;
            scareNear(vX + 5.0, vY, 22.0);
        }
    }

    function drawVisitor(dc) {
        if (visitor == 1) {
            var paw = 0x281E1C;
            for (var dy = 0; dy < 4; dy++) {
                Gfx.line(dc, vX - 2.0, vY + dy, vX + 2.0, vY + dy, paw);
            }
            Gfx.px(dc, vX - 3.0, vY + 4.0, paw);
            Gfx.px(dc, vX - 1.0, vY + 5.0, paw);
            Gfx.px(dc, vX + 1.0, vY + 5.0, paw);
            Gfx.px(dc, vX + 3.0, vY + 4.0, paw);
        } else if (visitor == 2) {
            var duck = 0xFFC828;
            for (var d2 = 0; d2 < 3; d2++) {
                Gfx.line(dc, vX, vY + d2, vX + 4.0, vY + d2, duck);
            }
            Gfx.px(dc, vX + 5.0, vY + 1.0, 0xFF7814);
            Gfx.px(dc, vX + 1.0, vY - 1.0, 0xFFDC50);
        } else if (visitor == 3) {
            Gfx.px(dc, vX, vY, 0xDCDCF0);
            Gfx.px(dc, vX, vY + 1.0, 0x1E5AB4);
            Gfx.px(dc, vX, vY + 2.0, 0x1E5AB4);
            Gfx.px(dc, vX - 1.0, vY + 1.0, 0xC82828);
            Gfx.px(dc, vX + 1.0, vY + 3.0, 0xB4B4C8);
        } else if (visitor == 4) {
            for (var d3 = -10; d3 <= 10; d3++) {
                var ady = d3;
                if (ady < 0) { ady = -ady; }
                var shade = 18 + ady;
                Gfx.line(dc, vX, vY + d3, vX + 9.0, vY + d3, Colour.rgb(shade, shade, shade + 8));
            }
        }
    }

    // ---- day context ---------------------------------------------------

    function checkDay(now) {
        if (lastDayCheck != 0 && now - lastDayCheck < 60000) {
            return;
        }
        lastDayCheck = now;
        var g = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dow = g.day_of_week;
        weekend = (dow == 1 || dow == 7);
        boids.setWeekend(weekend);
    }

    function applyWeekendSchooling() {
        if (!weekend || creatures.size() == 0) {
            return;
        }
        var cx = 0.0;
        var cy = 0.0;
        var n = 0;
        for (var i = 0; i < creatures.size(); i++) {
            var c = creatures[i];
            if (!c.isPokeable()) { continue; }
            cx += c.x();
            cy += c.y();
            n++;
        }
        if (n == 0) {
            return;
        }
        cx = cx / n;
        cy = cy / n;
        for (var k = 0; k < creatures.size(); k++) {
            var ck = creatures[k];
            if (ck.isPokeable()) {
                ck.schoolToward(cx, cy);
            }
        }
    }

    // ---- one frame -----------------------------------------------------

    function step(now) {
        checkDay(now);
        applyWeekendSchooling();
        handleAutonomousLife(now);
        boids.update(dt);
        for (var i = 0; i < creatures.size(); i++) {
            creatures[i].update(now, dt);
        }
        // keep the cast at NUM_FISH; every 20 to 40 min swap the oldest for a
        // fresh weighted pick
        if (creatures.size() < Cfg.NUM_FISH) {
            spawnAt(creatures.size(), nextRosterSpecies(), now);
            scheduleNextRefill(now);
        } else if (now >= nextRefillMs) {
            if (creatures.size() > 0) {
                creatures = creatures.slice(1, creatures.size());
                spawnAt(creatures.size(), nextRosterSpecies(), now);
            }
            scheduleNextRefill(now);
        }
        var keep = [];
        for (var k = 0; k < foods.size(); k++) {
            var f = foods[k];
            f.update(dt);
            if (f.eaten) {
                pelletsEaten++;
            } else if (!f.offScreen) {
                keep.add(f);
            }
        }
        foods = keep;
        updateVisitors(now);
    }

    function draw(dc, now) {
        boids.draw(dc);
        for (var i = 0; i < creatures.size(); i++) {
            creatures[i].draw(dc, now, dt);
        }
        for (var k = 0; k < foods.size(); k++) {
            foods[k].draw(dc);
        }
        for (var n = 0; n < plants.size(); n++) {
            plants[n].draw(dc, now);
        }
        drawVisitor(dc);
    }
}
