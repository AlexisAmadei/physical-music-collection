import Foundation

/// What a Finish looks like, as plain data: no drawing here, so it is the same on both platforms and testable.
/// Mirrors Android `WaxPattern.kt` (same generator, same steps, same numbers). The look was settled with the browser
/// prototype on branch prototype/vinyl-finishes: Marble is warped noise, Splatter is bursts of elongated droplets.

/// SplitMix64, the same generator as Android `WaxRandom` and `SeededRandom`: a fixed seed always draws the same thing.
struct WaxRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// In 0..<1.
    mutating func unit() -> Double { Double(next() >> 11) / Double(UInt64(1) << 53) }
}

/// An ellipse on the unit disc (radius 1, origin at the centre, y down), turned by `rot` radians.
struct Droplet: Equatable, Sendable {
    let x: Double
    let y: Double
    let rx: Double
    let ry: Double
    let rot: Double
    let alpha: Double
    /// Glitter flecks only: 0 (strongest), 1 or 2, turned into a tint of the wax by `WaxPattern.fleckColor`.
    var tone: Int = 0
}

/// A flake that flashes when the phone tilts. It has its own flashing angles: `a` and `b`, in radians per unit of tilt,
/// and `phase`. `r` is its size on the unit disc. See `WaxPattern.glintLevel`.
struct Glint: Equatable, Sendable {
    let x: Double
    let y: Double
    let r: Double
    let a: Double
    let b: Double
    let phase: Double
}

/// Galaxy stars: `dots` are fine white points of varied size, `glows` a few bigger stars drawn with a halo.
struct Stars: Equatable, Sendable {
    let dots: [Droplet]
    let glows: [Droplet]
}

extension Disc {
    /// The seed of the Disc's pattern. From the creation time: stable across launches and edits, different for each Disc.
    /// Not the persistent id: that is not a stable number. Same value as Android `Disc.waxSeed` for the same time.
    var waxSeed: UInt64 { WaxPattern.seed(addedAt: addedAt) }
}

extension Draft {
    /// The seed of the pattern the Draft's Disc will have.
    var waxSeed: UInt64 { WaxPattern.seed(addedAt: addedAt) }
}

enum WaxPattern {
    private static let tau = 2 * Double.pi

    /// Marble bitmap side, in pixels. One bitmap per Disc, drawn scaled.
    static let marbleSize = 256

    /// The seed for a creation time (milliseconds since 1970, as Android stores it).
    static func seed(addedAt: Date) -> UInt64 {
        let millis = Int64((addedAt.timeIntervalSince1970 * 1000).rounded(.down))
        var random = WaxRandom(seed: UInt64(bitPattern: millis))
        return random.next()
    }

    private static func inDisc(_ rand: inout WaxRandom, radius: Double) -> (Double, Double) {
        let a = rand.unit() * tau
        let d = rand.unit().squareRoot() * radius
        return (cos(a) * d, sin(a) * d)
    }

    /// Splatter: a few impact points, each a core blob throwing elongated droplets outward.
    static func splatter(seed: UInt64) -> [Droplet] {
        var rand = WaxRandom(seed: seed)
        var out: [Droplet] = []
        let impacts = 4 + Int(floor(rand.unit() * 3))
        for _ in 0..<impacts {
            let (cx, cy) = inDisc(&rand, radius: 0.85)
            let core = 5 + Int(floor(rand.unit() * 4))
            for _ in 0..<core {
                let a = rand.unit() * tau
                let d = rand.unit() * 0.05
                let r = 0.025 + rand.unit() * 0.05
                out.append(Droplet(x: cx + cos(a) * d, y: cy + sin(a) * d, rx: r, ry: r, rot: 0, alpha: 0.97))
            }
            let n = 90 + Int(floor(rand.unit() * 70))
            let reach = 0.3 + rand.unit() * 0.3
            for _ in 0..<n {
                let a = rand.unit() * tau
                let d = 0.05 - log(1 - rand.unit()) * reach * 0.5
                let r = max(0.005, 0.07 * exp(-d * 4) * (0.3 + rand.unit() * 0.9))
                let e = 1 + d * 7 * rand.unit()
                out.append(Droplet(x: cx + cos(a) * d, y: cy + sin(a) * d, rx: r * e, ry: r, rot: a, alpha: 0.96))
            }
        }
        return out
    }

    /// Galaxy: stars over the nebula.
    static func stars(seed: UInt64) -> Stars {
        var rand = WaxRandom(seed: seed &+ 1)
        var dots: [Droplet] = []
        for _ in 0..<260 {
            let (x, y) = inDisc(&rand, radius: 1.02)
            let r = 0.003 + pow(rand.unit(), 4) * 0.014
            let alpha = 0.45 + rand.unit() * 0.5
            dots.append(Droplet(x: x, y: y, rx: r, ry: r, rot: 0, alpha: alpha))
        }
        var glows: [Droplet] = []
        for _ in 0..<14 {
            let (x, y) = inDisc(&rand, radius: 0.98)
            let r = 0.022 + rand.unit() * 0.02
            glows.append(Droplet(x: x, y: y, rx: r, ry: r, rot: 0, alpha: 1))
        }
        return Stars(dots: dots, glows: glows)
    }

    /// Glitter: about 1400 flecks of mixed size and brightness. Each fleck has a tone, 0 (strongest), 1 or 2, that
    /// `fleckColor` turns into a tint of the wax: light flecks on dark wax, dark flecks on light wax.
    static func flecks(seed: UInt64) -> [Droplet] {
        var rand = WaxRandom(seed: seed &+ 2)
        var out: [Droplet] = []
        for _ in 0..<1400 {
            let (x, y) = inDisc(&rand, radius: 1.02)
            let r = 0.003 + pow(rand.unit(), 3) * 0.013
            let k = rand.unit()
            let tone = k < 0.45 ? 0 : (k < 0.8 ? 1 : 2)
            let alpha = 0.35 + rand.unit() * 0.6
            out.append(Droplet(x: x, y: y, rx: r, ry: r, rot: 0, alpha: alpha, tone: tone))
        }
        return out
    }

    /// The opaque ARGB of a Glitter fleck of `tone` on wax of the `base` color.
    static func fleckColor(base: VinylColor, tone: Int) -> UInt32 {
        let wax = rgb(base)
        let white: [Double] = [255, 255, 255]
        let black: [Double] = [0, 0, 0]
        let c: [Double]
        if base.light {
            switch tone {
            case 0: c = mix(wax, black, 0.5)
            case 1: c = mix(wax, black, 0.22)
            default: c = white
            }
        } else {
            switch tone {
            case 0: c = white
            case 1: c = mix(wax, white, 0.5)
            default: c = mix(wax, black, 0.4)
            }
        }
        let r = UInt32(c[0])
        let g = UInt32(c[1])
        let b = UInt32(c[2])
        return 0xFF00_0000 | (r << 16) | (g << 8) | b
    }

    /// Split: the angle, in radians, of the line between the two colors. The second color is on the far side of it.
    static func splitAngle(seed: UInt64) -> Double {
        var rand = WaxRandom(seed: seed &+ 3)
        return rand.unit() * tau
    }

    // MARK: Marble: domain-warped value noise, thresholded into bands

    private static func hash2(_ ix: Int32, _ iy: Int32, _ s: Int32) -> Double {
        var h: Int32 = ix &* 374_761_393 &+ iy &* 668_265_263 &+ s &* 1_597_334_677
        h = (h ^ Int32(bitPattern: UInt32(bitPattern: h) >> 13)) &* 1_274_126_177
        h ^= Int32(bitPattern: UInt32(bitPattern: h) >> 16)
        return Double(UInt32(bitPattern: h)) / 4_294_967_296.0
    }

    private static func vnoise(_ x: Double, _ y: Double, _ s: Int32) -> Double {
        let fx0 = floor(x)
        let fy0 = floor(y)
        let ix = Int32(truncatingIfNeeded: Int(fx0))
        let iy = Int32(truncatingIfNeeded: Int(fy0))
        let fx = x - fx0
        let fy = y - fy0
        let u = fx * fx * fx * (fx * (fx * 6 - 15) + 10)
        let v = fy * fy * fy * (fy * (fy * 6 - 15) + 10)
        let a = hash2(ix, iy, s)
        let b = hash2(ix &+ 1, iy, s)
        let c = hash2(ix, iy &+ 1, s)
        let d = hash2(ix &+ 1, iy &+ 1, s)
        return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v
    }

    private static func fbm(_ x: Double, _ y: Double, _ s: Int32) -> Double {
        var t = 0.0
        var amp = 0.5
        var f = 1.0
        for i in 0..<4 {
            t += amp * vnoise(x * f, y * f, s &+ Int32(i) &* 31)
            f *= 2
            amp *= 0.5
        }
        return t / 0.9375
    }

    private static func smooth(_ a: Double, _ b: Double, _ x: Double) -> Double {
        let t = min(1, max(0, (x - a) / (b - a)))
        return t * t * (3 - 2 * t)
    }

    private static func mix(_ a: [Double], _ b: [Double], _ t: Double) -> [Double] {
        [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t]
    }

    private static func rgb(_ color: VinylColor) -> [Double] {
        let argb = color.argb
        return [Double((argb >> 16) & 0xFF), Double((argb >> 8) & 0xFF), Double(argb & 0xFF)]
    }

    /// Marble as `size` x `size` ARGB pixels (straight alpha, row by row, top first) covering the square around the disc;
    /// draw it clipped to the disc. A Clear `base` stays see-through where the `second` color is absent.
    static func marble(seed: UInt64, base: VinylColor, second: VinylColor, size n: Int = marbleSize) -> [UInt32] {
        var rand = WaxRandom(seed: seed)
        let s0 = Int32(floor(rand.unit() * 1e6))
        var o: [Double] = []
        for _ in 0..<6 { o.append(rand.unit() * 80) }
        let scale = 1.45
        let baseRgb = rgb(base)
        let secRgb = rgb(second)
        let baseAlpha = Double(base.argb >> 24) / 255.0
        let veinRgb = second.light ? mix(secRgb, [0, 0, 0], 0.35) : mix(secRgb, [255, 255, 255], 0.4)
        let mid = mix(baseRgb, secRgb, 0.5)
        var out = [UInt32](repeating: 0, count: n * n)
        for y in 0..<n {
            for x in 0..<n {
                let px = ((Double(x) + 0.5) / Double(n) * 2 - 1) * scale
                let py = ((Double(y) + 0.5) / Double(n) * 2 - 1) * scale
                let qx = fbm(px + o[0], py + o[1], s0)
                let qy = fbm(px + o[2], py + o[3], s0 &+ 7)
                let rx = fbm(px + 3.2 * qx + o[4], py + 3.2 * qy + 1.7, s0 &+ 13)
                let ry = fbm(px + 3.2 * qx + 8.3, py + 3.2 * qy + o[5], s0 &+ 19)
                let f = fbm(px + 3.2 * rx, py + 3.2 * ry, s0 &+ 29)
                let band = 0.5 + 0.5 * sin((f - 0.5) * tau * 2.1 + 0.6)
                let t = smooth(0.3, 0.7, band)
                let edge = exp(-pow((band - 0.5) / 0.09, 2))
                var col = mix(baseRgb, secRgb, t)
                col = mix(col, mid, edge * 0.45)
                let vein = exp(-pow((band - 0.5) / 0.03, 2)) * 0.45
                col = mix(col, veinRgb, vein)
                let alpha = baseAlpha + (1 - baseAlpha) * t
                let a = UInt32((alpha * 255).rounded())
                let r = UInt32(col[0])
                let g = UInt32(col[1])
                let b = UInt32(col[2])
                out[y * n + x] = (a << 24) | (r << 16) | (g << 8) | b
            }
        }
        return out
    }

    /// Galaxy nebula as `size` x `size` ARGB pixels, like `marble` but smooth: soft clouds of the `second` color over the
    /// `base`, with brighter cores. Stars are drawn over it from `stars`.
    static func nebula(seed: UInt64, base: VinylColor, second: VinylColor, size n: Int = marbleSize) -> [UInt32] {
        var rand = WaxRandom(seed: seed)
        let s0 = Int32(floor(rand.unit() * 1e6))
        var o: [Double] = []
        for _ in 0..<6 { o.append(rand.unit() * 80) }
        let scale = 1.3
        let baseRgb = rgb(base)
        let secRgb = rgb(second)
        let baseAlpha = Double(base.argb >> 24) / 255.0
        let lite = mix(secRgb, [255, 255, 255], 0.35)
        var out = [UInt32](repeating: 0, count: n * n)
        for y in 0..<n {
            for x in 0..<n {
                let px = ((Double(x) + 0.5) / Double(n) * 2 - 1) * scale
                let py = ((Double(y) + 0.5) / Double(n) * 2 - 1) * scale
                let qx = fbm(px + o[0], py + o[1], s0)
                let qy = fbm(px + o[2], py + o[3], s0 &+ 7)
                let f = fbm(px + 2.2 * qx + o[4], py + 2.2 * qy + o[5], s0 &+ 13)
                let t = smooth(0.38, 0.78, f)
                let core = smooth(0.62, 0.9, f)
                var col = mix(baseRgb, secRgb, t)
                col = mix(col, lite, core * 0.5)
                let alpha = baseAlpha + (1 - baseAlpha) * t
                let a = UInt32((alpha * 255).rounded())
                let r = UInt32(col[0])
                let g = UInt32(col[1])
                let b = UInt32(col[2])
                out[y * n + x] = (a << 24) | (r << 16) | (g << 8) | b
            }
        }
        return out
    }

    /// The bitmap under a Finish that has one: Marble (veined bands) or Galaxy (soft nebula); nil for the others.
    static func bitmap(finish: Finish, seed: UInt64, base: VinylColor, second: VinylColor, size n: Int = marbleSize) -> [UInt32]? {
        switch finish {
        case .marble: marble(seed: seed, base: base, second: second, size: n)
        case .galaxy: nebula(seed: seed, base: base, second: second, size: n)
        default: nil
        }
    }

    /// The glints that shimmer with the tilt: 150 small ones on Glitter, 40 bigger ones (the twinkling stars) on Galaxy,
    /// none on any other Finish. They are drawn over the still wax, which does not change.
    static func glints(finish: Finish?, seed: UInt64) -> [Glint] {
        let count: Int
        let minRadius: Double
        let radiusSpan: Double
        let stream: UInt64
        switch finish {
        case .glitter:
            (count, minRadius, radiusSpan, stream) = (150, 0.007, 0.011, 4)
        case .galaxy:
            (count, minRadius, radiusSpan, stream) = (40, 0.012, 0.016, 5)
        default:
            return []
        }
        var rand = WaxRandom(seed: seed &+ stream)
        var out: [Glint] = []
        for _ in 0..<count {
            let (x, y) = inDisc(&rand, radius: 0.97)
            let r = minRadius + rand.unit() * radiusSpan
            let a = (rand.unit() * 2 - 1) * 14
            let b = (rand.unit() * 2 - 1) * 14
            let phase = rand.unit() * tau
            out.append(Glint(x: x, y: y, r: r, a: a, b: b, phase: phase))
        }
        return out
    }

    /// How brightly a `glint` flashes, 0 to 1, for a phone tilt of (`tiltX`, `tiltY`), each in -1...1. A spiky cosine: a
    /// glint is dark most of the time and flashes when the tilt faces its own angle, so a tilting phone makes them twinkle.
    static func glintLevel(_ glint: Glint, tiltX: Double, tiltY: Double) -> Double {
        pow(max(0, cos(glint.a * tiltX + glint.b * tiltY + glint.phase)), 12)
    }
}
