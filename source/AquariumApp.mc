using Toybox.Application;
using Toybox.WatchUi;

// Globals shared by the tank and the views.
var gTank = null;    // Tank (the simulation)
var gGuide = null;   // Guide (which species have been found; saved on the watch)

class AquariumApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        gGuide = new Guide();
        gTank = new Tank();
    }

    function onStop(state) {
        if (gGuide != null) {
            gGuide.save();
        }
    }

    function getInitialView() {
        var v = new TankView();
        return [v, new TankDelegate(v)];
    }
}
