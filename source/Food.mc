using Toybox.Math;

// Port of lib/Aquarium/Food.h. A flake starts at the top edge of the circle
// above its x and sinks until it leaves the circle at the bottom.
class Food {
    var x;
    var y;
    var eaten = false;
    var offScreen = false;
    var bottomY;

    const FALL_SPEED = 0.3;   // tank units per CYD frame

    function initialize(dropX) {
        x = dropX;
        var dx = x - Cfg.C;
        if (dx > Cfg.R - 1.0) { dx = Cfg.R - 1.0; }
        if (dx < -(Cfg.R - 1.0)) { dx = -(Cfg.R - 1.0); }
        x = Cfg.C + dx;
        var h = Math.sqrt(Cfg.R * Cfg.R - dx * dx);
        y = Cfg.C - h;
        bottomY = Cfg.C + h;
    }

    function update(dt) {
        y += FALL_SPEED * dt;
        if (y >= bottomY) {
            offScreen = true;
        }
    }

    function draw(dc) {
        if (eaten) {
            return;
        }
        // amber three-pixel flake
        Gfx.px(dc, x, y, 0xFFB428);
        Gfx.px(dc, x + 1.0, y, 0xDC7814);
        Gfx.px(dc, x, y + 1.0, 0xDC7814);
    }

    function eat() {
        eaten = true;
    }
}
