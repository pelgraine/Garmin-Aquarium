// Tank settings. The CYD aquarium works on an 80-wide logical grid at 30
// frames a second; the watch shows the same grid at 3 screen pixels per unit
// inside the fenix 7S circle (centre 120,120, radius 120 on screen).
module Cfg {
    // One tank frame every this many ms. 100 = 10 frames a second. The
    // Garmin timer floor is 50 ms. Everything else scales from this.
    const FRAME_MS = 100;

    // The CYD's own frame period (30 a second). Motion per watch frame is
    // multiplied by FRAME_MS / CYD_FRAME_MS so creatures cover the same
    // distance per second as on the CYD whatever FRAME_MS is.
    const CYD_FRAME_MS = 33.333;

    // Tank geometry, in tank units (1 unit = 3 screen pixels).
    const R = 40.0;        // tank radius
    const C = 40.0;        // tank centre (x and y)
    const KEEP_R = 34.0;   // creatures are steered back inside this radius
                           // (the CYD's keep-inside margin of 6 units)

    // CYD physics scale: the CYD runs motion in units 80 times finer than
    // the grid. Speeds and forces from the CYD are divided by this.
    const PHYS = 80.0;

    // Creature drawing scale for the silhouettes still drawn the CYD way
    // (clownfish, tangs, Moorish idol, sergeant, sweeper, silverside,
    // dartfish, surgeon, unicorn, star, moray, octopus). 1.0 is the CYD's
    // own size (tiny on the watch); every body dimension is multiplied by
    // this. Eyes, lines and the dot grid stay one unit.
    const CREATURE_SCALE = 1.8;

    // Size of the outline drawings (chromis, fusilier, anthias, cardinal,
    // sharks, whale shark, humpback, manta, turtle). 1.0 is the size agreed
    // from the mock-ups (a chromis about 36 px nose to tail, a whale shark
    // about 75 px); everything else scales from it. Age still varies each
    // creature a little either side.
    const OUTLINE_SCALE = 1.0;

    // Spawn weight given to the big species (both reef sharks, whale shark,
    // reef manta, humpback, sea turtle) in place of the CYD's 1 to 3, so
    // they turn up every so often. 16 is the weight of one chromis species:
    // the six together are then about 9% of picks, so about half of tanks
    // start with one, and later swaps bring one about every 10 to 12 swaps.
    const BIG_WEIGHT = 16;

    // Population (CYD PANEL_CYD_TFT has 12 fish; fewer here to make room
    // for the larger bodies).
    const NUM_FISH = 8;
    const NUM_PLANTS = 3;
    const BOID_GROUPS = 2;
    const BOIDS_MIN = 6;    // CYD: random(10, 20) per group; fewer here to
    const BOIDS_MAX = 10;   // keep the flocking maths down on the watch

    // Autonomous feeding (CYD esp32-2432s028r build).
    const FOOD_BOOT_MIN_MS = 1500;
    const FOOD_BOOT_MAX_MS = 3500;
    const FOOD_MIN_MS = 5500;
    const FOOD_MAX_MS = 12000;
    const MAX_FOOD = 3;

    // Species roster refill (swap the oldest for a fresh pick).
    const REFILL_MIN_MS = 1200000;   // 20 min
    const REFILL_MAX_MS = 2400000;   // 40 min

    // Age thresholds (AquariumSettings.h).
    const AGE_EGG = 0.1;
    const AGE_ADULT = 0.7;
    const AGE_SENIOR = 0.9;
    const AGE_DEAD = 1.0;
    const LIFESPAN_DAYS = 7.0;
    const LIFESPAN_VARIATION = 1.0;

    // Overlay colours.
    const COL_BUBBLE = 0xFFF5B4;
    const COL_DIARY = 0xC8F0DC;
    const COL_FPS = 0x808080;

    function dt() {
        return FRAME_MS / CYD_FRAME_MS;
    }
}
