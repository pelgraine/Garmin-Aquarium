using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Timer;

// The tank screen. One timer (the app's only one) asks for a redraw every
// Cfg.FRAME_MS; each redraw advances the simulation one frame and paints it:
// black water, boids, creatures, food, plants, visitor, then the dot grid
// over the lot, then the text overlays (discovery bubble, diary, fps).
//   tap        drop a food flake at that x
//   Up         show the diary line for 8 s
//   Start      open the Reef Guide (the tank pauses while it is open)
//   Down       show or hide the frames-per-second figure
//   Back       leave the app
class TankView extends WatchUi.View {
    const FONT = Graphics.FONT_XTINY;
    const MID = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    var _timer;
    var _grid = null;
    var _stepDue = false;
    var _showFps = true;
    var _frames = 0;
    var _fpsAt = 0;
    var _fps = 0.0;

    function initialize() {
        View.initialize();
        _timer = new Timer.Timer();
    }

    function onLayout(dc) {
        _grid = WatchUi.loadResource(Rez.Drawables.Grid);
    }

    function onShow() {
        _fpsAt = System.getTimer();
        _frames = 0;
        _timer.start(method(:tick), Cfg.FRAME_MS, true);
    }

    function onHide() {
        _timer.stop();
    }

    function tick() {
        _stepDue = true;
        WatchUi.requestUpdate();
    }

    function toggleFps() {
        _showFps = !_showFps;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        var now = System.getTimer();
        if (_stepDue) {
            _stepDue = false;
            gTank.step(now);
            _frames++;
            if (now - _fpsAt >= 1000) {
                _fps = _frames * 1000.0 / (now - _fpsAt);
                _frames = 0;
                _fpsAt = now;
            }
        }
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setPenWidth(Gfx.S);
        gTank.draw(dc, now);
        dc.setPenWidth(1);
        if (_grid != null) {
            dc.drawBitmap(0, 0, _grid);
        }

        var b = gTank.bubble(now);
        if (b != null) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(121, 41, FONT, b, MID);
            dc.setColor(Cfg.COL_BUBBLE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(120, 40, FONT, b, MID);
        }
        var d = gTank.diary(now);
        if (d != null) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(121, 115, FONT, d, MID);
            dc.setColor(Cfg.COL_DIARY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(120, 114, FONT, d, MID);
        }
        if (_showFps) {
            dc.setColor(Cfg.COL_FPS, Graphics.COLOR_TRANSPARENT);
            dc.drawText(120, 212, FONT, _fps.format("%.1f") + " fps", MID);
        }
    }
}

class TankDelegate extends WatchUi.BehaviorDelegate {
    var _v;

    function initialize(v) {
        BehaviorDelegate.initialize();
        _v = v;
    }

    // Up: diary. Down: fps figure on or off.
    function onPreviousPage() {
        gTank.showDiary(System.getTimer());
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() {
        _v.toggleFps();
        return true;
    }

    // Start (top right): Reef Guide. Read directly so screen taps still
    // arrive as onTap.
    function onKey(evt) {
        if (evt.getKey() == WatchUi.KEY_ENTER) {
            var g = new GuideView();
            WatchUi.pushView(g, new GuideDelegate(g), WatchUi.SLIDE_LEFT);
            return true;
        }
        return false;
    }

    // Tap: a food flake dropped at that x.
    function onTap(evt) {
        var c = evt.getCoordinates();
        gTank.dropPellet(c[0] / 3.0, System.getTimer());
        return true;
    }
}
