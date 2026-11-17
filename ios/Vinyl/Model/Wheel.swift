import Foundation

extension AppModel {
    /// The Collection as Home's cover wheel shows it: newest added first (Android `sortedByDescending { addedAt }`).
    /// Ignores the Collection screen's filter and sort.
    var homeDiscs: [Disc] { CollectionFilter().apply(to: collection) }
}

/// Where a card sits on the wheel at `theta` degrees from the front (Android `Modifier.onWheel` and the white veil).
/// Positive `theta` is below the front card.
struct WheelPlacement: Equatable, Sendable {
    /// Card side, points.
    static let card = 200.0
    /// Wheel radius, points: ten cards 20 pt apart around the wheel (≈ 356 pt).
    static let radius = (card + 20) / (2 * sin(.pi / Double(WheelMotion.slots)))
    /// Camera distance, points.
    static let perspective = 1000.0

    /// The card's tilt about the horizontal axis, degrees.
    let theta: Double
    /// Vertical offset of the card's centre from the wheel's centre, points.
    let offsetY: Double
    /// Size compared with the front card (smaller towards the back).
    let scale: Double
    /// Opacity of the white veil, stronger towards the back: 0 in front, 0.55 at the back.
    let veil: Double
    /// Drawing order: 1 in front, -1 at the back.
    let depth: Double

    init(theta: Double) {
        let rad = theta * .pi / 180
        let facing = cos(rad)
        self.theta = theta
        offsetY = Self.radius * sin(rad)
        scale = Self.perspective / (Self.perspective + Self.radius * (1 - facing))
        veil = 0.55 * pow((1 - facing) / 2, 1.25)
        depth = facing
    }
}

/// Home's cover wheel position, as pure logic (Android `WheelState` in `ui/Wheel.kt`).
///
/// The wheel is an endless tape: card `k` sits at `k · spacing + angle` degrees and shows Disc `k mod n`.
/// Only the `slots` cards around the front are drawn, so a Collection of any size scrolls through in order.
struct WheelMotion: Equatable, Sendable {
    /// Cards on the wheel.
    static let slots = 10
    /// Degrees between two cards.
    static let spacing = 360.0 / Double(slots)

    /// Wheel angle in degrees. Turning up (towards newer → older Discs) makes it more negative.
    var angle = 0.0

    /// The card nearest the front.
    var front: Int { Int((-angle / Self.spacing).rounded()) }

    /// The card that will be in front once the wheel settles.
    var heading: Int { Int((-(target ?? angle) / Self.spacing).rounded()) }

    /// Card `k`'s angle from the front, degrees (positive = below the front).
    func theta(card k: Int) -> Double { Double(k) * Self.spacing + angle }

    /// The cards drawn: the `slots` cards around the front.
    var cards: Range<Int> { (front - Self.slots / 2)..<(front + Self.slots / 2) }

    /// Whether a finger is turning the wheel.
    private(set) var dragging = false
    /// The angle the wheel springs to, if any.
    private var target: Double?
    /// Spring speed, degrees per second.
    private var velocity = 0.0

    /// Spring stiffness (critically damped).
    private static let stiffness = 118.0
    /// Fastest fling, degrees per second.
    private static let maxFling = 1400.0

    /// The wheel is still: no finger, no spring under way, on a card.
    var isSettled: Bool { !dragging && target == nil && angle == Self.nearest(angle) }

    // MARK: Finger

    /// A finger starts turning the wheel: it stops whatever it was doing.
    mutating func startDrag() {
        target = nil
        velocity = 0
        dragging = true
    }

    /// The finger moved, turning the wheel by that many degrees.
    mutating func drag(byDegrees degrees: Double) {
        guard dragging else { return }
        angle += degrees
    }

    /// The finger lifts: the wheel carries on a quarter second at the fling speed and lands on a card.
    mutating func endDrag(degreesPerSecond speed: Double) {
        guard dragging else { return }
        dragging = false
        target = Self.nearest(angle + min(max(speed, -Self.maxFling), Self.maxFling) * 0.25)
        pause = Self.touchPause
    }

    /// A finger that touched the wheel lifted (dragging or not): the drift waits a moment.
    mutating func touchEnded() {
        pause = max(pause, Self.touchPause)
    }

    // MARK: Taps and VoiceOver

    /// Turns card `k` to the front ("Disque suivant" and "Disque précédent", or a tap on a card).
    mutating func focus(card k: Int) {
        target = -Double(k) * Self.spacing
        pause = Self.tapPause
    }

    /// Moves the front by that many cards: +1 is "Disque suivant", -1 "Disque précédent".
    /// Repeated before the wheel settles, the steps add up.
    mutating func step(by cards: Int) {
        target = (target ?? Self.nearest(angle)) - Double(cards) * Self.spacing
        pause = Self.tapPause
    }

    // MARK: Frames

    /// Seconds left before the idle drift may start again.
    private var pause = 0.0

    /// Idle drift, degrees per second (upwards).
    private static let drift = 10.0
    /// Drift pause after a touch, seconds.
    private static let touchPause = 2.5
    /// Drift pause after a tap or a VoiceOver action, seconds.
    private static let tapPause = 2.8

    /// Moves the wheel on by one frame of `dt` seconds.
    /// - Parameter canDrift: whether the idle wheel may drift now: no finger down, no open sleeve, motion allowed.
    mutating func tick(dt: Double, canDrift: Bool) {
        guard !dragging else { return }
        let dt = min(dt, 0.05)
        pause = max(0, pause - dt)
        var a = angle
        if let t = target {
            let damping = 2 * Self.stiffness.squareRoot()
            var rest = dt
            while rest > 0 {
                let h = min(rest, 1.0 / 240)
                velocity += (Self.stiffness * (t - a) - damping * velocity) * h
                a += velocity * h
                rest -= h
            }
            if abs(t - a) < 0.01 && abs(velocity) < 0.05 {
                a = t
                target = nil
                velocity = 0
            }
        } else if canDrift && pause == 0 {
            a -= Self.drift * dt
        } else if abs(a - Self.nearest(a)) > 0.01 {
            target = Self.nearest(a)
        }
        angle = a
    }

    private static func nearest(_ a: Double) -> Double { (a / spacing).rounded() * spacing }

    /// The index of the Disc card `k` shows, in a list of `count` Discs.
    func disc(atCard k: Int, count: Int) -> Int {
        Self.floorMod(k, count)
    }

    /// The position indicator's thumb: 0 when the newest Disc is in front, 1 for the oldest.
    static func indicator(front: Int, count: Int) -> Double {
        count < 2 ? 0 : Double(floorMod(front, count)) / Double(count - 1)
    }

    private static func floorMod(_ k: Int, _ n: Int) -> Int {
        let r = k % n
        return r < 0 ? r + n : r
    }
}
