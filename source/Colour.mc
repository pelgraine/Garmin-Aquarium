// FastLED's hsv2rgb_rainbow (as shipped in GFX_Lite, FASTLED_SCALE8_FIXED=1),
// so the species keep the CYD's colours. Hue, sat and val are 0..255.
// Returns 0xRRGGBB.
module Colour {
    function scale8(i, s) {
        return (i * (s + 1)) >> 8;
    }

    function scale8v(i, s) {
        var j = (i * s) >> 8;
        if (i != 0 && s != 0) {
            j += 1;
        }
        return j;
    }

    function rgb(r, g, b) {
        return (r << 16) | (g << 8) | b;
    }

    // Mix a 0xRRGGBB colour toward white by f (0..1).
    function lighter(c, f) {
        var r = (c >> 16) & 0xFF;
        var g = (c >> 8) & 0xFF;
        var b = c & 0xFF;
        r = r + ((255 - r) * f).toNumber();
        g = g + ((255 - g) * f).toNumber();
        b = b + ((255 - b) * f).toNumber();
        return rgb(r, g, b);
    }

    // Scale a 0xRRGGBB colour by f (0..1): darker, or faded with age.
    function scaled(c, f) {
        var r = (((c >> 16) & 0xFF) * f).toNumber();
        var g = (((c >> 8) & 0xFF) * f).toNumber();
        var b = ((c & 0xFF) * f).toNumber();
        return rgb(r, g, b);
    }

    function hsv(hue, sat, val) {
        var offset8 = (hue & 0x1F) << 3;
        var third = scale8(offset8, 85);
        var r = 0;
        var g = 0;
        var b = 0;
        var twothirds = 0;
        if ((hue & 0x80) == 0) {
            if ((hue & 0x40) == 0) {
                if ((hue & 0x20) == 0) {
                    r = 255 - third; g = third; b = 0;
                } else {
                    r = 171; g = 85 + third; b = 0;
                }
            } else {
                if ((hue & 0x20) == 0) {
                    twothirds = scale8(offset8, 170);
                    r = 171 - twothirds; g = 170 + third; b = 0;
                } else {
                    r = 0; g = 255 - third; b = third;
                }
            }
        } else {
            if ((hue & 0x40) == 0) {
                if ((hue & 0x20) == 0) {
                    twothirds = scale8(offset8, 170);
                    r = 0; g = 171 - twothirds; b = 85 + twothirds;
                } else {
                    r = third; g = 0; b = 255 - third;
                }
            } else {
                if ((hue & 0x20) == 0) {
                    r = 85 + third; g = 0; b = 171 - third;
                } else {
                    r = 170 + third; g = 0; b = 85 - third;
                }
            }
        }
        if (sat != 255) {
            if (sat == 0) {
                r = 255; g = 255; b = 255;
            } else {
                var desat = 255 - sat;
                desat = scale8v(desat, desat);
                var satscale = 255 - desat;
                r = scale8(r, satscale) + desat;
                g = scale8(g, satscale) + desat;
                b = scale8(b, satscale) + desat;
            }
        }
        if (val != 255) {
            var v = scale8v(val, val);
            if (v == 0) {
                r = 0; g = 0; b = 0;
            } else {
                r = scale8(r, v);
                g = scale8(g, v);
                b = scale8(b, v);
            }
        }
        if (r > 255) { r = 255; }
        if (g > 255) { g = 255; }
        if (b > 255) { b = 255; }
        return rgb(r, g, b);
    }
}
