using Toybox.Math;

// Random helpers with the Arduino random() ranges the CYD code uses.
module Rnd {
    // 0 .. n-1
    function below(n) {
        if (n <= 0) {
            return 0;
        }
        return (Math.rand() & 0x7FFFFFFF) % n;
    }

    // a .. b-1 (Arduino random(a, b))
    function range(a, b) {
        if (b <= a) {
            return a;
        }
        return a + below(b - a);
    }

    // 0.0 .. 1.0
    function unit() {
        return below(10001) / 10000.0;
    }

    // -1.0 .. 1.0
    function signed() {
        return unit() * 2.0 - 1.0;
    }
}
