#!/usr/bin/env python3
# Builds Species.mc (Monkey C) from the CYD aquarium's SpeciesCatalog.h.
# Usage: python3 -I gen_species.py <path to SpeciesCatalog.h> <output Species.mc>
import re
import sys

src = open(sys.argv[1], encoding="utf-8").read()

sil_names = [
    "Schooler", "ChromisShoal", "Fusilier", "Anthias", "Cardinal", "Sergeant",
    "Sweeper", "Silverside", "Dartfish", "Surgeon", "Unicorn", "Clownfish",
    "BlueTang", "YellowTang", "MoorishIdol", "Turtle", "Star", "Snake",
    "Octopus", "Shark", "WhaleShark", "Manta", "Whale", "Prop",
]
size_names = ["Tiny", "Small", "Medium", "Large"]
motion_names = {"Fish": 0, "Turtle": 1, "Star": 2, "Snake": 3, "Octopus": 4}

pat = re.compile(
    r'\{SpeciesId::(\w+),\s*"([^"]*)",\s*"([^"]*)",\s*"([^"]*)",\s*'
    r'"([^"]*)",\s*(true|false),\s*(\d+),\s*SilhouetteKind::(\w+),\s*'
    r'SizeClass::(\w+),\s*(\d+),\s*(\d+),\s*(\d+)\}',
    re.S,
)
rows = pat.findall(src)
if len(rows) != 103:
    sys.exit("expected 103 species, parsed %d" % len(rows))

# Check the enum order matches the table order.
enum_block = src[src.index("enum class SpeciesId"):src.index("Count\n};")]
enum_ids = re.findall(r"^\s*(\w+)(?: = 0)?,\s*$", enum_block, re.M)
table_ids = [r[0] for r in rows]
if enum_ids != table_ids:
    sys.exit("enum order differs from table order")

def mc_str(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'

def arr(name, values, per_line, fmt=str):
    out = ["    var %s = [" % name]
    line = "       "
    for i, v in enumerate(values):
        piece = " " + fmt(v) + ("," if i < len(values) - 1 else "")
        if len(line) + len(piece) > 96:
            out.append(line)
            line = "       "
        line += piece
    out.append(line)
    out.append("    ];")
    return "\n".join(out)

ids = [r[0] for r in rows]
short = [r[3] for r in rows]
desc = [r[4] for r in rows]
swim = [1 if r[5] == "true" else 0 for r in rows]
weight = [int(r[6]) for r in rows]
sil = [sil_names.index(r[7]) for r in rows]
size = [size_names.index(r[8]) for r in rows]
motion = [motion_names.get(r[2], 5) for r in rows]
hue = [int(r[9]) for r in rows]
sat = [int(r[10]) for r in rows]
val = [int(r[11]) for r in rows]

lines = []
lines.append("using Toybox.Lang;")
lines.append("")
lines.append("// Species catalogue, generated from the CYD aquarium's SpeciesCatalog.h")
lines.append("// (github.com/francistse/esp32-cyd-aquarium, AGPL-3.0). Do not edit by hand;")
lines.append("// rerun gen_species.py. One entry per species, in the catalogue's order.")
lines.append("module Species {")
lines.append("    const COUNT = %d;" % len(rows))
lines.append("")
lines.append("    // Silhouette kinds (SIL)")
for i, n in enumerate(sil_names):
    lines.append("    const SIL_%s = %d;" % (re.sub(r"(?<!^)(?=[A-Z])", "_", n).upper(), i))
lines.append("")
lines.append("    // Size classes (SIZE)")
for i, n in enumerate(size_names):
    lines.append("    const SIZE_%s = %d;" % (n.upper(), i))
lines.append("")
lines.append("    // Motion types (MOTION)")
for n, i in motion_names.items():
    lines.append("    const MOTION_%s = %d;" % (n.upper(), i))
lines.append("    const MOTION_NONE = 5;")
lines.append("")
lines.append("    // Named ids used by the tank code")
for name in ["Clownfish", "Chromis", "Anemone", "Kelp", "FishFlake", "BlueGreenChromis", "GreenSeaTurtle"]:
    lines.append("    const ID_%s = %d;" % (re.sub(r"(?<!^)(?=[A-Z])", "_", name).upper(), ids.index(name)))
lines.append("")
lines.append(arr("NAME", short, 0, mc_str))
lines.append("")
lines.append(arr("DESC", desc, 0, mc_str))
lines.append("")
lines.append(arr("SWIM", swim, 0))
lines.append("")
lines.append(arr("WEIGHT", weight, 0))
lines.append("")
lines.append(arr("SIL", sil, 0))
lines.append("")
lines.append(arr("SIZE", size, 0))
lines.append("")
lines.append(arr("MOTION", motion, 0))
lines.append("")
lines.append(arr("HUE", hue, 0))
lines.append("")
lines.append(arr("SAT", sat, 0))
lines.append("")
lines.append(arr("VAL", val, 0))
lines.append("")
lines.append("""    // sizeClassScale() from SpeciesCatalog.h
    function sizeScale(id) {
        var sz = SIZE[id];
        if (sz == SIZE_TINY) { return 0.55; }
        if (sz == SIZE_SMALL) { return 0.75; }
        if (sz == SIZE_LARGE) { return 1.25; }
        return 1.0;
    }

    // pickWeightedSwimmer(): a weighted random swimmer, skipping any id whose
    // entry in exclude is true (exclude may be null).
    function pickWeightedSwimmer(exclude) {
        var total = 0;
        for (var i = 0; i < COUNT; i++) {
            if (SWIM[i] == 0 || WEIGHT[i] == 0) { continue; }
            if (exclude != null && exclude[i]) { continue; }
            total += WEIGHT[i];
        }
        if (total == 0) {
            return ID_BLUE_GREEN_CHROMIS;
        }
        var roll = Rnd.below(total);
        for (var j = 0; j < COUNT; j++) {
            if (SWIM[j] == 0 || WEIGHT[j] == 0) { continue; }
            if (exclude != null && exclude[j]) { continue; }
            if (roll < WEIGHT[j]) {
                return j;
            }
            roll -= WEIGHT[j];
        }
        return ID_BLUE_GREEN_CHROMIS;
    }
}""")

open(sys.argv[2], "w", encoding="utf-8").write("\n".join(lines) + "\n")
print("wrote", sys.argv[2], len(rows), "species")
