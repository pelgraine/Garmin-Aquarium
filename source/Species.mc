using Toybox.Lang;

// Species catalogue, generated from the CYD aquarium's SpeciesCatalog.h
// (github.com/francistse/esp32-cyd-aquarium, AGPL-3.0). Do not edit by hand;
// rerun gen_species.py. One entry per species, in the catalogue's order.
module Species {
    const COUNT = 103;

    // Silhouette kinds (SIL)
    const SIL_SCHOOLER = 0;
    const SIL_CHROMIS_SHOAL = 1;
    const SIL_FUSILIER = 2;
    const SIL_ANTHIAS = 3;
    const SIL_CARDINAL = 4;
    const SIL_SERGEANT = 5;
    const SIL_SWEEPER = 6;
    const SIL_SILVERSIDE = 7;
    const SIL_DARTFISH = 8;
    const SIL_SURGEON = 9;
    const SIL_UNICORN = 10;
    const SIL_CLOWNFISH = 11;
    const SIL_BLUE_TANG = 12;
    const SIL_YELLOW_TANG = 13;
    const SIL_MOORISH_IDOL = 14;
    const SIL_TURTLE = 15;
    const SIL_STAR = 16;
    const SIL_SNAKE = 17;
    const SIL_OCTOPUS = 18;
    const SIL_SHARK = 19;
    const SIL_WHALE_SHARK = 20;
    const SIL_MANTA = 21;
    const SIL_WHALE = 22;
    const SIL_PROP = 23;

    // Size classes (SIZE)
    const SIZE_TINY = 0;
    const SIZE_SMALL = 1;
    const SIZE_MEDIUM = 2;
    const SIZE_LARGE = 3;

    // Motion types (MOTION)
    const MOTION_FISH = 0;
    const MOTION_TURTLE = 1;
    const MOTION_STAR = 2;
    const MOTION_SNAKE = 3;
    const MOTION_OCTOPUS = 4;
    const MOTION_NONE = 5;

    // Named ids used by the tank code
    const ID_CLOWNFISH = 88;
    const ID_CHROMIS = 99;
    const ID_ANEMONE = 100;
    const ID_KELP = 101;
    const ID_FISH_FLAKE = 102;
    const ID_BLUE_GREEN_CHROMIS = 0;
    const ID_GREEN_SEA_TURTLE = 90;
    const ID_BLACKTIP_REEF_SHARK = 94;
    const ID_WHITETIP_REEF_SHARK = 95;
    const ID_WHALE_SHARK = 96;
    const ID_REEF_MANTA = 97;
    const ID_HUMPBACK_WHALE = 98;

    var NAME = [
        "BLUE GREEN CHR", "BLACK AXIL CHR", "BLACKBAR CHR", "BICOLOR CHR", "AMBON CHR",
        "TERNATE CHR", "WEBERS CHR", "BARRIER CHR", "DARKFIN CHR", "DEEP REEF CHR",
        "YELLOW CHR", "SPINY CHR", "HALF HALF CHR", "MIDGET CHR", "OVATE CHR", "PALE CHR",
        "PEARL CHR", "SAPPHIRE CHR", "SCISSOR CHR", "STAGHORN CHR", "SURGE CHR", "TWINSPOT CHR",
        "VANDERBILT CHR", "WHITETAIL CHR", "FUSILIER DAMSEL", "GREEN CHR", "INDIGO CHR",
        "REEF CHR", "BLUE YEL FUSIL", "BLUESTREAK FUS", "RUDDY FUSILIER", "GOLDBAND FUS",
        "DOUBLE LINE FUS", "YELBACK FUS", "LUNAR FUSILIER", "MOJICA FUSILIER", "STRIATED FUS",
        "WIDEBAND FUS", "LYRETAIL ANTH", "THREADFIN ANTH", "PURPLE ANTHIAS", "BARTLETT ANTH",
        "SQUAREBACK ANT", "FLAME ANTHIAS", "RESPLEND ANTH", "REDFIN ANTHIAS", "YELBACK ANTH",
        "PRINCESS ANTH", "SUNSHINE ANTH", "DISPAR ANTHIAS", "EVANS ANTHIAS", "LORI ANTHIAS",
        "PASCUL ANTHIAS", "RANDALL ANTH", "SMITH ANTHIAS", "HAWK ANTHIAS", "BLACKSTRIPE CD",
        "RINGTAIL CARD", "PAJAMA CARD", "FROSTFIN CARD", "REDSPOT CARD", "THREADFIN CARD",
        "FIVE LINE CARD", "OCHRE CARDINAL", "BLUE EYE CARD", "FRAGILE CARD", "GIRDLED CARD",
        "LEVELFIN CARD", "SANGI CARDINAL", "SPOTFIN CARD", "TINY CARDINAL", "BANGGAI CARD",
        "BLUE TANG", "YELLOW TANG", "CONVICT TANG", "SERGEANT MAJOR", "GOLDEN SWEEPER",
        "COPPER SWEEPER", "HARDYHEAD", "BLUE SPRAT", "SCISSOR SGT", "INDIGO DART",
        "FIRE DARTFISH", "YEL TAIL SURG", "POWDER SURG", "ORANGE UNICORN", "SPOT UNICORN",
        "BRASSY CHUB", "CLOWNFISH", "MOORISH IDOL", "SEA TURTLE", "STARFISH", "MORAY",
        "OCTOPUS", "BLACKTIP SHARK", "WHITETIP SHARK", "WHALE SHARK", "REEF MANTA", "HUMPBACK",
        "CHROMIS", "ANEMONE", "KELP", "FISH FLAKE"
    ];

    var DESC = [
        "SHOALS ABOVE CORAL AND FACES THE CURRENT TO EAT PLANKTON.",
        "A GREEN SHOALER WITH A DARK SPOT AT THE PECTORAL FIN BASE.",
        "A SMALL DAMSEL WITH A DARK BAR NEAR THE TAIL.",
        "FRONT HALF DARK AND REAR HALF WHITE OVER THE REEF.",
        "A YELLOW BROWN SHOALER COMMON ON INDO PACIFIC REEFS.",
        "A SLENDER CHROMIS THAT FORMS TIGHT MIDWATER GROUPS.",
        "A DEEP BODIED CHROMIS OF OUTER REEF SLOPES.",
        "A PACIFIC CHROMIS OF THE GREAT BARRIER REEF.", "NAMED FOR THE DARK EDGES ON ITS FINS.",
        "HOVERS OVER DEEPER CORAL HEADS BY DAY.", "A BRIGHT YELLOW SHOALER OF CLEAR LAGOONS.",
        "A STOCKY CHROMIS WITH A SPINY DORSAL FIN.",
        "SPLIT COLOR MAKES IT EASY TO SPOT IN A MIXED SHOAL.",
        "ONE OF THE SMALLEST OPEN WATER DAMSELS.", "A ROUND BODIED CHROMIS OF BRANCHING CORAL.",
        "A PALE BLUE GREEN FISH IN LARGE CURTAINS.",
        "A SILVERY CHROMIS THAT GLINTS IN SUNLIGHT.",
        "DEEP BLUE SIDES STAND OUT AGAINST CORAL.",
        "A FORKED TAIL HELPS IT DART FROM PREDATORS.", "SHELTERS IN STAGHORN CORAL AT NIGHT.",
        "HOLDS IN WAVE SURGE ON THE REEF CREST.", "TWO DARK SPOTS MARK THE REAR OF THE BODY.",
        "A PACIFIC SHOALER OF CLEAR OUTER REEFS.", "A WHITE CAUDAL FIN FLASHES AS IT TURNS.",
        "A STREAMLINED DAMSEL THAT SHOALS LIKE A FUSILIER.",
        "METALLIC GREEN SIDES IN LOOSE MIDWATER GROUPS.",
        "DARK BLUE FISH THAT FORM DENSE CLOUDS.",
        "A COMMON GENERALIST SHOALER OVER HARD CORAL.",
        "SCHOOLS IN OPEN WATER WITH A BRIGHT YELLOW BACK.",
        "A FAST SCHOOLER WITH A BLUE LATERAL STREAK.",
        "REDDISH SIDES IN TIGHT MIDWATER SCHOOLS.", "A GOLD BAND RUNS THE LENGTH OF THE BODY.",
        "TWO STRIPES MARK THIS ACTIVE SCHOOLER.",
        "YELLOW ABOVE AND BLUE BELOW IN LARGE SCHOOLS.",
        "A SILVERY FUSILIER OF CLEAR TROPICAL SEAS.", "A PACIFIC FUSILIER OF OUTER REEF WALLS.",
        "FINE STRIPES COVER A STREAMLINED BODY.",
        "A BROAD COLOR BAND HELPS THE SCHOOL STAY TIGHT.",
        "A PINK ORANGE SHOALER WITH A LYRE SHAPED TAIL.",
        "LONG THREAD LIKE FINS STREAM FROM THE BODY.",
        "PURPLE AND YELLOW FISH IN LOOSE SHOALS.",
        "A PACIFIC ANTHIAS WITH A BRIGHT ORANGE BODY.",
        "A SQUARED TAIL MARKS THIS REEF SHOALER.",
        "A FIERY RED ORANGE FISH OF CURRENT SWEPT REEFS.",
        "BRIGHT COLORS HELP MALES HOLD A HAREM.", "RED FINS FLASH AS THE SHOAL TURNS.",
        "YELLOW ON THE BACK OVER A PINK BODY.", "A SLENDER ANTHIAS OF DEEP REEF SLOPES.",
        "YELLOW ORANGE FISH THAT HOVER IN CURRENT.", "A SMALL PACIFIC ANTHIAS IN MIXED SHOALS.",
        "A DEEP WATER ANTHIAS WITH A LONG DORSAL FIN.",
        "A COMPACT ANTHIAS OF CORAL RICH SLOPES.", "A SOUTH PACIFIC SHOALER ABOVE CORAL HEADS.",
        "NAMED AFTER A FAMED REEF FISH TAXONOMIST.", "A STOCKY ANTHIAS OF INDIAN OCEAN REEFS.",
        "A SWIFT ANTHIAS THAT DARTS AT PLANKTON.",
        "DARK STRIPES RUN THE LENGTH OF A SMALL BODY.",
        "A GOLD RING MARKS THE BASE OF THE TAIL.", "SPOTS AND BARS LOOK LIKE SLEEPWEAR.",
        "PALE FINS EDGE A REDDISH BODY.", "A RED SPOT SITS NEAR THE BASE OF THE TAIL.",
        "LONG FILAMENTS TRAIL FROM THE FINS.", "FIVE STRIPES MAKE IT EASY TO COUNT IN A GROUP.",
        "A WARM BROWN CARDINAL OF LAGOON CORAL.", "A BRIGHT BLUE EYE STANDS OUT AT DUSK.",
        "A SLENDER CARDINAL THAT HIDES BY DAY.", "A DARK GIRDLE CROSSES THE MID BODY.",
        "EVEN FINS SUIT A QUIET HOVERING HABIT.", "A CARDINAL OF INDONESIAN REEF CAVES.",
        "A DARK SPOT MARKS THE DORSAL FIN.", "ONE OF THE SMALLEST REEF CARDINALS.",
        "A RARE CARDINAL FROM A SMALL INDONESIAN RANGE.",
        "A SURGEONFISH THAT GRAZES ALGAE IN LOOSE GROUPS.",
        "A REEF HERBIVORE THAT CROPS ALGAE WITH OTHERS.",
        "BLACK BARS CROSS A SILVER BODY IN LARGE GRAZING GROUPS.",
        "BOLD BARS MARK A DAMSEL THAT FORMS LOOSE GROUPS.", "DENSE SCHOOLS FILL CAVES BY DAY.",
        "COPPER SIDES GLINT IN CAVE MOUTH SCHOOLS.",
        "SILVERY FISH THAT FORM TRUE POLARIZED SCHOOLS.",
        "A SMALL HERRING LIKE SCHOOLER OF LAGOONS.",
        "A FORKED TAIL AND BARS MARK THIS GROUP DAMSEL.",
        "PAIRS OR SMALL GROUPS HOVER ABOVE BURROWS.",
        "AN ORANGE BODY AND WHITE TAIL OVER SAND.", "A DARK SURGEON WITH A BRIGHT YELLOW TAIL.",
        "A PALE BLUE SURGEON THAT GRAZES IN LOOSE GROUPS.",
        "A UNICORNFISH THAT JOINS GRAZING GROUPS.", "SPOTS COVER A LARGE GRAZING UNICORNFISH.",
        "A BRASSY SCHOOLER OF THE REEF SURF ZONE.",
        "LIVES IN A HOST ANEMONE. MUCUS BLOCKS THE STING.",
        "A LONG SNOUT PICKS SPONGES. THE STREAMER IS A DORSAL FIN.",
        "ADULTS GRAZE SEAGRASS. FEMALES RETURN HOME TO NEST.",
        "NO BRAIN AND NO BLOOD. TUBE FEET WALK ON ROCK.",
        "A CREVICE HUNTER WITH A SECOND JAW IN THE THROAT.",
        "EIGHT ARMS AND THREE HEARTS. SKIN SHIFTS COLOR TO VANISH.",
        "A REEF SHARK WITH BLACK FIN TIPS. IT PATROLS SHALLOW FLATS.",
        "A SLENDER REEF SHARK THAT RESTS IN CAVES BY DAY.",
        "THE LARGEST FISH. IT FILTERS PLANKTON ON LONG MIGRATIONS.",
        "A WIDE WINGED RAY THAT LOOPS THROUGH PLANKTON CLOUDS.",
        "A LONG LIVED WHALE. SONGS AND FLIPPERS MARK THE SPECIES.",
        "TINY BLUE SCHOOLERS RENDERED AS BACKGROUND DOTS.",
        "AN ANIMAL POLYP. STINGING CELLS CATCH PREY.",
        "A BROWN ALGA. BLADES MAKE FOOD FROM SUNLIGHT.",
        "PRESSED FLAKES THAT SINK AND FEED THE SWIMMERS."
    ];

    var SWIM = [
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0
    ];

    var WEIGHT = [
        16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
        16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 8, 8, 8, 8, 8, 8, 8, 8,
        8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 2, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 1, 1, 2, 2, 1, 1, 1, 0, 0, 0, 0
    ];

    var SIL = [
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 12, 13, 5, 5, 6, 6, 7, 7, 5, 8, 8, 9, 9, 10,
        10, 5, 11, 14, 15, 16, 17, 18, 19, 19, 20, 21, 22, 23, 23, 23, 23
    ];

    var SIZE = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 1, 0, 0, 0, 0, 1, 0, 0, 2, 2, 2, 2,
        1, 1, 2, 3, 2, 3, 3, 3, 3, 3, 3, 3, 0, 1, 2, 0
    ];

    var MOTION = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 1, 2, 3, 4, 0, 0, 0, 0, 1, 5, 5, 5, 5
    ];

    var HUE = [
        150, 145, 160, 0, 35, 155, 140, 148, 130, 165, 42, 120, 10, 155, 150, 140, 0, 170, 145,
        155, 135, 40, 160, 0, 150, 100, 175, 150, 45, 160, 5, 40, 35, 48, 0, 150, 30, 50, 5, 10,
        200, 15, 8, 0, 20, 5, 40, 200, 35, 10, 15, 5, 12, 8, 18, 0, 0, 35, 200, 5, 0, 10, 20,
        25, 160, 0, 15, 30, 5, 10, 0, 0, 160, 40, 0, 40, 40, 20, 0, 160, 35, 170, 10, 160, 155,
        25, 0, 35, 18, 0, 90, 230, 80, 200, 0, 0, 0, 170, 0, 160, 0, 90, 30
    ];

    var SAT = [
        180, 200, 160, 0, 180, 170, 150, 190, 200, 160, 230, 140, 50, 120, 170, 80, 0, 220, 190,
        160, 180, 200, 180, 0, 160, 200, 210, 150, 220, 200, 200, 230, 180, 220, 0, 170, 160,
        200, 220, 200, 180, 230, 210, 240, 220, 230, 200, 160, 230, 180, 200, 210, 190, 220,
        200, 200, 0, 200, 100, 180, 200, 160, 150, 180, 100, 80, 140, 120, 160, 170, 100, 0,
        220, 240, 0, 200, 220, 180, 0, 100, 190, 200, 230, 180, 200, 200, 40, 150, 230, 0, 150,
        180, 180, 180, 0, 20, 0, 80, 40, 180, 150, 200, 220
    ];

    var VAL = [
        255, 255, 240, 230, 240, 250, 230, 255, 240, 230, 255, 220, 220, 240, 245, 250, 245,
        255, 250, 235, 240, 240, 255, 250, 245, 230, 220, 240, 255, 255, 230, 250, 245, 255,
        240, 245, 235, 250, 255, 250, 255, 255, 245, 255, 255, 250, 250, 245, 255, 240, 245,
        250, 245, 250, 245, 240, 220, 240, 230, 230, 230, 235, 230, 220, 240, 230, 220, 225,
        230, 235, 240, 245, 255, 255, 240, 255, 250, 230, 245, 250, 250, 240, 255, 220, 255,
        240, 230, 220, 255, 245, 200, 255, 200, 220, 180, 200, 220, 230, 160, 255, 220, 180, 255
    ];

    // sizeClassScale() from SpeciesCatalog.h
    function sizeScale(id) {
        var sz = SIZE[id];
        if (sz == SIZE_TINY) { return 0.55; }
        if (sz == SIZE_SMALL) { return 0.75; }
        if (sz == SIZE_LARGE) { return 1.25; }
        return 1.0;
    }

    // Spawn weight: the CYD's, except the six big species get Cfg.BIG_WEIGHT.
    function weightOf(i) {
        if (i == ID_BLACKTIP_REEF_SHARK || i == ID_WHITETIP_REEF_SHARK || i == ID_WHALE_SHARK
            || i == ID_REEF_MANTA || i == ID_HUMPBACK_WHALE || i == ID_GREEN_SEA_TURTLE) {
            return Cfg.BIG_WEIGHT;
        }
        return WEIGHT[i];
    }

    // pickWeightedSwimmer(): a weighted random swimmer, skipping any id whose
    // entry in exclude is true (exclude may be null).
    function pickWeightedSwimmer(exclude) {
        var total = 0;
        for (var i = 0; i < COUNT; i++) {
            if (SWIM[i] == 0 || weightOf(i) == 0) { continue; }
            if (exclude != null && exclude[i]) { continue; }
            total += weightOf(i);
        }
        if (total == 0) {
            return ID_BLUE_GREEN_CHROMIS;
        }
        var roll = Rnd.below(total);
        for (var j = 0; j < COUNT; j++) {
            if (SWIM[j] == 0 || weightOf(j) == 0) { continue; }
            if (exclude != null && exclude[j]) { continue; }
            if (roll < weightOf(j)) {
                return j;
            }
            roll -= weightOf(j);
        }
        return ID_BLUE_GREEN_CHROMIS;
    }
}
