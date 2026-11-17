import Foundation

/// The open sleeve on Home's cover wheel, as pure logic (Android `FlipState` in `ui/Wheel.kt`).
///
/// Front → flipping → vinyl out, then the reverse. The vinyl comes out once the sleeve first faces backwards
/// (the flip's overshoot settles meanwhile) and is tucked back in before the sleeve turns. Every step can be
/// interrupted: a new open or close picks up from wherever the sleeve is.
struct SleeveMotion: Equatable, Sendable {
    /// The wheel card whose sleeve is open, opening or closing.
    private(set) var card: Int?
    /// The sleeve's turn about its vertical axis, degrees: 0 = front, 180 = back. Overshoots a little.
    private(set) var rotation = 0.0
    /// How far the vinyl is out: 0 = hidden behind the sleeve, 1 = all the way out.
    private(set) var slide = 0.0
    /// The vinyl is drawn.
    private(set) var discVisible = false
    /// The vinyl turns (once it is all the way out).
    private(set) var spinning = false
    /// The vinyl's turn, degrees.
    private(set) var spin = 0.0
    /// The sleeve is shutting.
    private(set) var closing = false

    /// Open or opening: the wheel holds still. A closing sleeve already lets it go.
    var holding: Bool { card != nil && !closing }

    private var reduceMotion = false
    private var flip: Tween?
    private var slideTween: Tween?

    /// Vinyl turns per second, degrees (one turn in 1.8 s).
    static let spinSpeed = 200.0
    /// cubic-bezier(.3, 1.45, .55, 1): light overshoot (~5 %) at the end of the flip.
    static let flipEase = CubicBezier(0.3, 1.45, 0.55, 1)
    static let slideEase = CubicBezier(0.2, 0.8, 0.2, 1)
    /// Compose's default tween easing, used to tuck the vinyl back in.
    static let tuckEase = CubicBezier(0.4, 0, 0.2, 1)
    static let openSeconds = 0.75
    static let closeSeconds = 0.8
    static let slideOutSeconds = 0.5
    static let slideBackSeconds = 0.3

    /// A tap on wheel card `k` while card `front` is in front. Returns whether the wheel should turn to `k`.
    /// - An open sleeve closes; the wheel turns to the tapped card if it is another one.
    /// - The front card opens its sleeve.
    /// - Any other card just turns to the front.
    @discardableResult
    mutating func tap(card k: Int, front: Int, reduceMotion: Bool = false) -> Bool {
        if holding {
            close()
            return k != front
        }
        if k == front { open(card: k, reduceMotion: reduceMotion) }
        return true
    }

    /// Flips card `k` open. Another sleeve still settling shuts at once.
    mutating func open(card k: Int, reduceMotion: Bool = false) {
        if card != nil && card != k { reset() }
        card = k
        closing = false
        self.reduceMotion = reduceMotion
        if reduceMotion {
            flip = nil
            slideTween = nil
            rotation = 180
            discVisible = true
            slide = 1
            return
        }
        flip = rotation == 180 ? nil : Tween(from: rotation, to: 180, seconds: Self.openSeconds, easing: Self.flipEase)
        slideTween = discVisible ? slideOut() : nil
    }

    /// Tucks the vinyl in, then turns the sleeve back to its front. Does nothing unless open or opening.
    mutating func close() {
        guard holding else { return }
        closing = true
        spinning = false
        if reduceMotion {
            reset()
            return
        }
        if discVisible {
            flip = nil // the sleeve waits, facing backwards, for the vinyl to go in
            slideTween = Tween(from: slide, to: 0, seconds: Self.slideBackSeconds, easing: Self.tuckEase)
        } else {
            slideTween = nil
            flip = turnBack()
        }
    }

    /// Moves the sleeve on by one frame of `dt` seconds.
    mutating func tick(dt: Double) {
        guard card != nil else { return }
        let dt = min(dt, 0.05)
        if var tween = flip {
            tween.elapsed += dt
            rotation = tween.value
            flip = tween.done ? nil : tween
            if tween.done && closing {
                reset()
                return
            }
        }
        if !closing && !discVisible && rotation >= 180 {
            discVisible = true
            slideTween = slideOut()
        }
        if var tween = slideTween {
            tween.elapsed += dt
            slide = tween.value
            slideTween = tween.done ? nil : tween
            if tween.done {
                if closing {
                    discVisible = false
                    flip = turnBack()
                } else {
                    spinning = true
                }
            }
        }
        if spinning { spin = (spin + Self.spinSpeed * dt).truncatingRemainder(dividingBy: 360) }
    }

    private func slideOut() -> Tween {
        Tween(from: slide, to: 1, seconds: Self.slideOutSeconds, easing: Self.slideEase)
    }

    private func turnBack() -> Tween {
        Tween(from: rotation, to: 0, seconds: Self.closeSeconds, easing: Self.flipEase)
    }

    private mutating func reset() {
        self = SleeveMotion()
    }
}

/// A value moving from `from` to `to` over `seconds`, along `easing`.
struct Tween: Equatable, Sendable {
    let from: Double
    let to: Double
    let seconds: Double
    let easing: CubicBezier
    var elapsed = 0.0

    var done: Bool { elapsed >= seconds }
    var value: Double { from + (to - from) * easing(min(elapsed / seconds, 1)) }
}

/// A CSS-style cubic-bezier timing curve from (0, 0) to (1, 1). The y values may leave 0…1 to overshoot.
struct CubicBezier: Equatable, Sendable {
    let x1, y1, x2, y2: Double

    init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
        (self.x1, self.y1, self.x2, self.y2) = (x1, y1, x2, y2)
    }

    /// The eased progress at time fraction `x` (0…1).
    func callAsFunction(_ x: Double) -> Double {
        if x <= 0 { return 0 }
        if x >= 1 { return 1 }
        // Solve bezierX(t) = x; x is monotonic in t since x1 and x2 lie in 0…1.
        var low = 0.0, high = 1.0, t = x
        for _ in 0..<40 {
            let error = Self.bezier(t, x1, x2) - x
            if abs(error) < 1e-7 { break }
            if error > 0 { high = t } else { low = t }
            t = (low + high) / 2
        }
        return Self.bezier(t, y1, y2)
    }

    private static func bezier(_ t: Double, _ p1: Double, _ p2: Double) -> Double {
        let u = 1 - t
        return 3 * u * u * t * p1 + 3 * u * t * t * p2 + t * t * t
    }
}
