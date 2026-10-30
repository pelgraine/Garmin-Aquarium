using Toybox.Math;
using Toybox.System;

// Port of lib/Aquarium/Motion/*.h. Positions and speeds are in tank units
// (the CYD's physics values divided by PHYS). One difference: the CYD steers
// each creature with an OpenSimplex noise field; that is too much maths for
// the watch, so the same force is driven by a per-creature value that
// random-walks between -1 and 1 instead.
class Motion {
    var px;
    var py;
    var vx;
    var vy;
    var ax = 0.0;
    var ay = 0.0;
    var angle = 0.0;

    var maxSpeed;
    var minSpeed;
    var sinAmp;
    var sinFreq;
    var noiseAmp;
    var sideSine;     // true: sideSineMotion, false: frontSineMotion
    var useNoise;
    var angleOffset;
    var wander = 0.0;

    var outOfBoundary = false;
    var followingFood = false;
    var foodX = 0.0;
    var foodY = 0.0;
    var wiggling = false;
    var wiggleUntil = 0;
    var scared = false;
    var scareX = 0.0;
    var scareY = 0.0;
    var schooling = false;
    var schoolX = 0.0;
    var schoolY = 0.0;

    const MAX_FORCE = 0.0375;        // CYD MAX_FORCE 3 / 80
    const FOOD_FORCE = 0.075;        // CYD FOOD_FORCE 6 / 80
    const BOUNDARY_FORCE = 0.0025;   // CYD BOUNDARY_FORCE 0.2 / 80
    const TWO_PI = 6.283185;

    // kind: Species.MOTION_* constants
    function initialize(kind, x, y) {
        px = x;
        py = y;
        angleOffset = Rnd.unit() * TWO_PI;
        if (kind == Species.MOTION_TURTLE) {
            maxSpeed = 40.0 / 80.0; minSpeed = 5.0 / 80.0;
            sinAmp = 10.0 / 80.0; sinFreq = 0.001; noiseAmp = 1.0 / 80.0;
            sideSine = false; useNoise = true;
        } else if (kind == Species.MOTION_STAR) {
            maxSpeed = 30.0 / 80.0; minSpeed = 10.0 / 80.0;
            sinAmp = 5.0 / 80.0; sinFreq = 0.005; noiseAmp = 2.0 / 80.0;
            sideSine = false; useNoise = true;
        } else if (kind == Species.MOTION_SNAKE) {
            maxSpeed = 40.0 / 80.0; minSpeed = 20.0 / 80.0;
            sinAmp = 5.0 / 80.0; sinFreq = 0.005; noiseAmp = 6.0 / 80.0;
            sideSine = true; useNoise = true;
        } else if (kind == Species.MOTION_OCTOPUS) {
            maxSpeed = 35.0 / 80.0; minSpeed = 5.0 / 80.0;
            sinAmp = 8.0 / 80.0; sinFreq = 0.002; noiseAmp = 0.0;
            sideSine = false; useNoise = false;
        } else {
            // Fish
            maxSpeed = 30.0 / 80.0; minSpeed = 10.0 / 80.0;
            sinAmp = 2.0 / 80.0; sinFreq = 0.002; noiseAmp = 6.0 / 80.0;
            sideSine = true; useNoise = true;
        }
        // CYD: random(-10, 10) per axis until the magnitude is at least 5
        var m = 0.0;
        while (m < 5.0) {
            vx = Rnd.range(-10, 10).toFloat();
            vy = Rnd.range(-10, 10).toFloat();
            m = Math.sqrt(vx * vx + vy * vy);
        }
        vx = vx / 80.0;
        vy = vy / 80.0;
        angle = Math.atan2(vy, vx);
    }

    function heading() {
        return Math.atan2(vy, vx);
    }

    function applyForce(fx, fy) {
        ax += fx;
        ay += fy;
    }

    // Keep inside the circle of radius Cfg.KEEP_R: a push toward the centre
    // (the CYD pushes off its four rectangular margins).
    function boundaryCheck(force) {
        outOfBoundary = false;
        var dx = px - Cfg.C;
        var dy = py - Cfg.C;
        var d = Math.sqrt(dx * dx + dy * dy);
        if (d > Cfg.KEEP_R && d > 0.0) {
            applyForce(-dx / d * force, -dy / d * force);
            outOfBoundary = true;
        }
    }

    function sineMotion(nowMs) {
        var theta = heading();
        if (sideSine) {
            theta += Math.PI / 2.0;
        }
        var a = nowMs * sinFreq + angleOffset;
        var yOffset = Math.sin(a) * sinAmp;
        applyForce(Math.cos(theta) * yOffset, Math.sin(theta) * yOffset);
    }

    function noiseMotion() {
        wander += Rnd.signed() * 0.4;
        if (wander > 1.0) { wander = 1.0; }
        if (wander < -1.0) { wander = -1.0; }
        var noiseAngle = wander * TWO_PI;
        var mag = noiseAmp * wander;
        applyForce(Math.cos(noiseAngle) * mag, Math.sin(noiseAngle) * mag);
    }

    // One CYD frame's worth of motion, stretched by dt (watch frames are
    // longer than CYD frames).
    function update(age, stayInside, nowMs, dt) {
        if (age < Cfg.AGE_EGG) {
            vx = 0.0;
            vy = 0.0;
            return;
        }
        if (stayInside) {
            boundaryCheck(BOUNDARY_FORCE * 10.0);
        } else {
            boundaryCheck(BOUNDARY_FORCE);
        }
        if (!followingFood && !outOfBoundary) {
            sineMotion(nowMs);
            if (useNoise) {
                noiseMotion();
            }
        } else if (followingFood) {
            var fx = foodX - px;
            var fy = foodY - py;
            var m = Math.sqrt(fx * fx + fy * fy);
            if (m > 0.0) {
                applyForce(fx / m * FOOD_FORCE, fy / m * FOOD_FORCE);
            }
        }

        if (wiggling) {
            if (nowMs < wiggleUntil) {
                var sa = angle + Math.PI / 2.0;
                var s = MAX_FORCE * 2.0 * Math.sin(nowMs * 0.05);
                applyForce(Math.cos(sa) * s, Math.sin(sa) * s);
            } else {
                wiggling = false;
            }
        }

        if (scared) {
            var awx = px - scareX;
            var awy = py - scareY;
            var am = Math.sqrt(awx * awx + awy * awy);
            if (am < 0.1) {
                awx = Math.cos(angle + Math.PI);
                awy = Math.sin(angle + Math.PI);
                am = 1.0;
            }
            applyForce(awx / am * FOOD_FORCE, awy / am * FOOD_FORCE);
            scared = false;
        }

        if (schooling) {
            var tx = schoolX - px;
            var ty = schoolY - py;
            var tm = Math.sqrt(tx * tx + ty * ty);
            if (tm > 0.0) {
                var f = MAX_FORCE * 0.35;
                applyForce(tx / tm * f, ty / tm * f);
            }
            schooling = false;
        }

        // desired = vel + acc (acc stretched by dt), held between min and
        // max speed; CO2 is fixed at a good level so the max is never cut
        var dvx = vx + ax * dt;
        var dvy = vy + ay * dt;
        var dm = Math.sqrt(dvx * dvx + dvy * dvy);
        if (dm < minSpeed) {
            if (dm > 0.0) {
                dvx = dvx / dm * minSpeed;
                dvy = dvy / dm * minSpeed;
            } else {
                dvx = minSpeed;
                dvy = 0.0;
            }
            dm = minSpeed;
        }
        if (dm > maxSpeed) {
            dvx = dvx / dm * maxSpeed;
            dvy = dvy / dm * maxSpeed;
        }
        vx = dvx;
        vy = dvy;
        px += vx * dt;
        py += vy * dt;
        ax = 0.0;
        ay = 0.0;
        angle = Math.atan2(vy, vx);
        followingFood = false;
    }

    // Speed in the CYD's physics units (what the body drawers expect).
    function physSpeed() {
        return Math.sqrt(vx * vx + vy * vy) * Cfg.PHYS;
    }

    function followFood(x, y) {
        foodX = x;
        foodY = y;
        followingFood = true;
    }

    function startWiggle(nowMs, durationMs) {
        wiggling = true;
        wiggleUntil = nowMs + durationMs;
    }

    function scareFrom(x, y) {
        scareX = x;
        scareY = y;
        scared = true;
    }

    function schoolToward(x, y) {
        schoolX = x;
        schoolY = y;
        schooling = true;
    }
}
