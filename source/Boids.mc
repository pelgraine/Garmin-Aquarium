using Toybox.Math;

// Port of lib/EffectManager/Boid.* and lib/Aquarium/BoidManager.*: the tiny
// blue chromis that drift in the background. Positions are tank units. The
// CYD wraps boids across its rectangle; here they are steered back toward
// the centre when they reach the edge of the circle.
class Boid {
    var x;
    var y;
    var vx;
    var vy;
    var ax = 0.0;
    var ay = 0.0;
    var maxSpeed;
    var maxForce;

    function initialize(px, py) {
        x = px;
        y = py;
        vx = Rnd.below(256) / 255.0 - 0.5;
        vy = Rnd.below(256) / 255.0 - 0.5;
        maxSpeed = Rnd.range(4, 8) / 10.0;    // BOID_MAX_SPEED 4, 8
        maxForce = Rnd.range(1, 2) / 10.0;    // BOID_MAX_FORCE 1, 2
    }
}

class Boids {
    var groups = [];     // array of arrays of Boid
    var sep = 4.0;       // desiredseparation
    var nbr = 8.0;       // neighbordist

    function initialize() {
        for (var g = 0; g < Cfg.BOID_GROUPS; g++) {
            var group = [];
            var n = Rnd.range(Cfg.BOIDS_MIN, Cfg.BOIDS_MAX);
            for (var i = 0; i < n; i++) {
                var a = Rnd.unit() * 6.283185;
                var r = Rnd.unit() * (Cfg.R - 4.0);
                group.add(new Boid(Cfg.C + Math.cos(a) * r, Cfg.C + Math.sin(a) * r));
            }
            groups.add(group);
        }
    }

    function setWeekend(on) {
        if (on) {
            sep = 2.0;
            nbr = 14.0;
        } else {
            sep = 4.0;
            nbr = 8.0;
        }
    }

    // flock(): separation * 1.5 + alignment + cohesion, then update and the
    // edge steer. One pass per boid over its own group.
    function update(dt) {
        for (var g = 0; g < groups.size(); g++) {
            var group = groups[g];
            var n = group.size();
            for (var i = 0; i < n; i++) {
                var b = group[i];
                var sepX = 0.0;
                var sepY = 0.0;
                var sepN = 0;
                var aliX = 0.0;
                var aliY = 0.0;
                var aliN = 0;
                var cohX = 0.0;
                var cohY = 0.0;
                for (var k = 0; k < n; k++) {
                    if (k == i) { continue; }
                    var o = group[k];
                    var dx = b.x - o.x;
                    var dy = b.y - o.y;
                    var d = Math.sqrt(dx * dx + dy * dy);
                    if (d <= 0.0) { continue; }
                    if (d < sep) {
                        sepX += dx / d / d;
                        sepY += dy / d / d;
                        sepN++;
                    }
                    if (d < nbr) {
                        aliX += o.vx;
                        aliY += o.vy;
                        cohX += o.x;
                        cohY += o.y;
                        aliN++;
                    }
                }
                if (sepN > 0) {
                    sepX = sepX / sepN;
                    sepY = sepY / sepN;
                    var sm = Math.sqrt(sepX * sepX + sepY * sepY);
                    if (sm > 0.0) {
                        sepX = sepX / sm * b.maxSpeed - b.vx;
                        sepY = sepY / sm * b.maxSpeed - b.vy;
                        limitInto(b, sepX, sepY, 1.5);
                    }
                }
                if (aliN > 0) {
                    aliX = aliX / aliN;
                    aliY = aliY / aliN;
                    var am = Math.sqrt(aliX * aliX + aliY * aliY);
                    if (am > 0.0) {
                        aliX = aliX / am * b.maxSpeed - b.vx;
                        aliY = aliY / am * b.maxSpeed - b.vy;
                        limitInto(b, aliX, aliY, 1.0);
                    }
                    // cohesion: seek the neighbours' centre
                    cohX = cohX / aliN - b.x;
                    cohY = cohY / aliN - b.y;
                    var cm = Math.sqrt(cohX * cohX + cohY * cohY);
                    if (cm > 0.0) {
                        cohX = cohX / cm * b.maxSpeed - b.vx;
                        cohY = cohY / cm * b.maxSpeed - b.vy;
                        limitInto(b, cohX, cohY, 1.0);
                    }
                }
                // edge: steer toward the centre near the rim
                var ex = b.x - Cfg.C;
                var ey = b.y - Cfg.C;
                var ed = Math.sqrt(ex * ex + ey * ey);
                if (ed > Cfg.R - 2.0 && ed > 0.0) {
                    var wx = -ex / ed * b.maxSpeed - b.vx;
                    var wy = -ey / ed * b.maxSpeed - b.vy;
                    limitInto(b, wx, wy, 1.0);
                }
                // update (the force is stretched by dt like the creatures')
                b.vx += b.ax * dt;
                b.vy += b.ay * dt;
                var vm = Math.sqrt(b.vx * b.vx + b.vy * b.vy);
                if (vm > b.maxSpeed && vm > 0.0) {
                    b.vx = b.vx / vm * b.maxSpeed;
                    b.vy = b.vy / vm * b.maxSpeed;
                }
                b.x += b.vx * dt;
                b.y += b.vy * dt;
                b.ax = 0.0;
                b.ay = 0.0;
                // never leave the circle
                ex = b.x - Cfg.C;
                ey = b.y - Cfg.C;
                ed = Math.sqrt(ex * ex + ey * ey);
                if (ed > Cfg.R - 1.0 && ed > 0.0) {
                    b.x = Cfg.C + ex / ed * (Cfg.R - 1.0);
                    b.y = Cfg.C + ey / ed * (Cfg.R - 1.0);
                }
            }
        }
    }

    // steer limited to maxForce, scaled by weight, added to the acceleration
    function limitInto(b, fx, fy, weight) {
        var fm = Math.sqrt(fx * fx + fy * fy);
        if (fm > b.maxForce && fm > 0.0) {
            fx = fx / fm * b.maxForce;
            fy = fy / fm * b.maxForce;
        }
        b.ax += fx * weight;
        b.ay += fy * weight;
    }

    function scareFrom(sx, sy, radius) {
        for (var g = 0; g < groups.size(); g++) {
            var group = groups[g];
            for (var i = 0; i < group.size(); i++) {
                var b = group[i];
                var dx = b.x + b.vx - sx;
                var dy = b.y + b.vy - sy;
                var d = Math.sqrt(dx * dx + dy * dy);
                if (d <= radius && d > 0.0) {
                    var mag = b.maxSpeed * (radius - d) / radius;
                    limitInto(b, dx / d * mag - b.vx, dy / d * mag - b.vy, 1.0);
                }
            }
        }
    }

    // three pixels along the velocity: head, body, tail
    function draw(dc) {
        var body = 0x288CDC;
        var tail = 0x145AB4;
        for (var g = 0; g < groups.size(); g++) {
            var group = groups[g];
            for (var i = 0; i < group.size(); i++) {
                var b = group[i];
                var a = Math.atan2(b.vy, b.vx);
                var cx = Math.cos(a);
                var cy = Math.sin(a);
                Gfx.px(dc, b.x + cx, b.y + cy, body);
                Gfx.px(dc, b.x, b.y, body);
                Gfx.px(dc, b.x - cx, b.y - cy, tail);
            }
        }
    }
}
