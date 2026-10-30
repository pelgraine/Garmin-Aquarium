# Aquarium for the fenix 7S: notes (v0.3, 30 Oct 2026)

A Connect IQ watch app (Monkey C) carrying the tank from
francistse/esp32-cyd-aquarium (commit 80449b3) onto the fenix 7S's round
240x240 screen. Hand translated; nothing here is compiled from the C++.
Not Meck or LoRa related. AGPL-3.0, see LICENSE and NOTICE.

## Controls

- Tap: drop a food flake at that x.
- Up (middle left): the diary line for 8 s ("12H  12 ALIVE  34 EAT").
- Start (top right): the Reef Guide. In the guide: Up/Down move the
  highlight, Start opens the species, Back closes the page, a tap on a
  cell opens it, a swipe left/right turns the page.
- Down (bottom left): show or hide the frames-per-second figure.
- Back: leave the app.

The Light key (top left) cannot be read by a watch app, which is why the
diary is on Up.

## Layout

- The tank is the whole circle: radius 40 tank units (120 px) centred on
  (40, 40). Creatures are steered back inside radius 34 (the CYD's margin
  of 6). Each tank unit is a 3x3 screen cell; a 240x240 grid bitmap drawn
  over the frame blacks out the four corners of every cell, which gives
  the CYD's plus-shaped dots in one draw call.
- Plants: an anemone and two kelp rooted just below the lower arc, at 70,
  90 and 110 degrees, 7 units outside the circle (the CYD roots its three
  just below its bottom edge).

## Tuning (source/Cfg.mc)

- FRAME_MS = 100 (10 frames a second). Motion per frame is scaled by
  FRAME_MS / 33.3 so creatures cover the same distance per second as on
  the CYD at any frame period. The Garmin timer floor is 50 ms.
- OUTLINE_SCALE = 1.0: size of the outline drawings (see "Outline
  drawings" below). 1.0 is the size agreed from the mock-ups.
- CREATURE_SCALE = 1.8: size of the silhouettes still drawn the CYD way;
  every body dimension times this (1.0 is the CYD's own size, which was
  too small to read on the watch). Eyes, lines and the dot grid stay one
  unit. Circles keep their fractional radius here rather than rounding
  down to a whole unit as the CYD does.
- BIG_WEIGHT = 16: spawn weight of the two reef sharks, whale shark,
  manta, humpback and sea turtle (the CYD gives them 1 to 3). At 16 each
  the six are about 9% of picks: about half of tanks start with one, and
  a later swap brings one about every 10 to 12 swaps. Applied in
  Species.weightOf(); the CYD weights for everything else are untouched.
- NUM_FISH = 8 (CYD: 12), NUM_PLANTS = 3, BOID_GROUPS = 2, BOIDS_MIN/MAX = 6/10.
- Feeding, refill and age constants as in the CYD esp32-2432s028r build.

## What is carried over from the CYD build

The 103-species roster with weighted spawning and distinct boot species,
the six-segment fish silhouettes (15 kinds), sharks, whale shark, manta,
whale, turtle, starfish, moray, octopus, the tiny chromis boids, plants
with sway, food flakes and feeding, autonomous feeding, the 20 to 40 min
roster refill, curated boot ages, visitors (cat paw, duck, diver, shadow)
with the scare, weekend schooling, the "NEW <species>" discovery bubble,
the diary line, and the Reef Guide (index of silhouettes, detail page,
discovery saved on the watch).

## Outline drawings (v0.3)

On the watch the CYD's chain-of-circles fish read as blobs (E, 30 Oct
2026), so nine silhouettes are now drawn as fish outlines, agreed from
mock-ups: chromis shoal, fusilier, anthias and cardinal (together 93% of
spawns), the reef sharks (black or white fin tips by species), whale
shark, humpback, and the manta and turtle, both seen from above. Each is
a few filled polygons plus eye and detail pixels, drawn through
Gfx.polyF at screen-pixel precision rather than snapped to tank cells;
the dot grid still goes over them. The dorsal side is kept upward
whichever way the fish faces (mirrored when facing left, as sprite fish
are), so it flips sides when the heading crosses straight up or down.
Fins are a lighter tint of the body colour. The big species have fixed
colours (slate for the whale shark instead of the CYD's near-white, so
its spots show), faded with age like the rest. The CYD-style drawings
remain for clownfish, the tangs, Moorish idol, sergeant, sweeper,
silverside, dartfish, surgeon, unicorn, starfish, moray and octopus. The
Reef Guide portraits are unchanged.

## What is different

- Steering noise: the CYD drives each creature's wander with OpenSimplex
  noise. That is too much maths for Monkey C, so the same force is driven
  by a per-creature value that random-walks between -1 and 1 (Motion.mc).
- Water: flat black. The CYD's moving noise shimmer is left out (per-pixel
  maths); it would need pre-made bitmaps.
- Boids: 6 to 10 per group rather than 10 to 20, and they are steered
  back from the rim instead of wrapping across the rectangle.
- Colours: the CYD draws every creature at saturation 115 with a value that
  fades with age (ColorPalette::adjustColorByAgeAndHealth); that is kept.
  The CYD's TFT tone and saturation profile (panel-specific) is not
  applied, and the watch rounds everything to its 64 colours.
- Discovery is automatic: a species counts as found when it is spawned.
  Anemone, kelp and chromis are found at start, the fish flake at the
  first feed. Several first-run bubbles arrive together; only the latest
  shows.
- Left out, as decided or because they need the camera: tank camera and
  zoom, poke on tap, near-view details (eye highlights, spots, stripes),
  the overfeed mess (only reachable through the CYD's hold-to-feed),
  eggs (boot ages start above the egg age), TGIF, the clock overlay,
  sensor text. Fish ages are not saved between runs (the CYD build does
  not load them either); the Reef Guide is.
- The tank pauses while the Reef Guide is open.

## Files

- source/Cfg.mc        settings
- source/Species.mc    the roster, generated by docs/gen_species.py from
                       SpeciesCatalog.h (hue, sat, val, silhouette, size,
                       weight, motion, names, descriptions)
- source/Colour.mc     FastLED hsv2rgb_rainbow
- source/Gfx.mc        drawing in tank units (3 px per unit)
- source/Motion.mc     creature steering
- source/Creature.mc   a creature: age, motion, all silhouette drawing
                       (outline section first, then the CYD-style ones)
- source/Plant.mc, Food.mc, Boids.mc
- source/Tank.mc       the simulation: population, feeding, visitors,
                       weekend, bubble, diary
- source/Guide.mc      discovery store, portraits, the Reef Guide screens
- source/TankView.mc   the tank screen, the one timer, keys and tap
- resources/drawables/grid.png  the dot mask, from docs/gen_images.py

## Not yet established

- v0.1 measured 3.2 to 3.4 frames a second on the watch at FRAME_MS = 100
  (E, 27 Oct 2026); v0.2 and v0.3 not yet measured. The outlines are
  fewer draw calls per fish than the circle chains were.
- Memory use (Connect IQ gives a watch app on the 7S 768 KB; the guide
  table and bitmaps are far below that, but not measured).
- How the colours look on the 64-colour screen.
