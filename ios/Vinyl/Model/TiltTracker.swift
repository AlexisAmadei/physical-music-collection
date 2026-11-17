import Foundation

/// Card tilt, each axis in -1...1 (Android `Tilt`). x > 0: right edge pushed away. y > 0: bottom edge pushed away.
struct Tilt: Equatable, Sendable {
    var x: Double
    var y: Double

    static let zero = Tilt(x: 0, y: 0)
}

/// A rotation as a unit quaternion (w, x, y, z).
struct Quaternion: Equatable, Sendable {
    var w: Double
    var x: Double
    var y: Double
    var z: Double

    static let identity = Quaternion(w: 1, x: 0, y: 0, z: 0)

    var conjugate: Quaternion { Quaternion(w: w, x: -x, y: -y, z: -z) }
    static prefix func - (q: Quaternion) -> Quaternion { Quaternion(w: -q.w, x: -q.x, y: -q.y, z: -q.z) }

    func dot(_ o: Quaternion) -> Double { w * o.w + x * o.x + y * o.y + z * o.z }

    /// self · o.
    static func * (a: Quaternion, b: Quaternion) -> Quaternion {
        Quaternion(
            w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
            x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
            y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
            z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w
        )
    }
}

/// Phone pose → `Tilt` (port of the Android `TiltTracker`). Zero is the pose of the first sample, so any holding
/// angle works (sofa, bed). The zero then drifts after the phone (`recenter` time constant): a held tilt fades back
/// to flat.
///
/// Poses are unit quaternions, device → world (Core Motion attitude, see `DevicePose`).
struct TiltTracker {
    private let range: Double
    private let recenter: Double
    private var base: Quaternion?

    /// `rangeDegrees`: the turn that gives a full tilt. `recenter`: seconds.
    init(rangeDegrees: Double = 15, recenter: Double = 3) {
        range = rangeDegrees * .pi / 180
        self.recenter = recenter
    }

    mutating func reset() { base = nil }

    /// `dt`: seconds since the last sample.
    mutating func update(_ q: Quaternion, dt: Double) -> Tilt {
        var b = base ?? q
        // Same rotation, other sign: keep q on b's side so the blend below takes the short way.
        let cur = b.dot(q) < 0 ? -q : q
        let rel = b.conjugate * cur // current device frame → zero frame
        let s: Double = rel.w < 0 ? -2 : 2 // small angle: 2 · vector part ≈ rotation in radians
        let tilt = Tilt(
            x: (s * rel.y / range).clamped(to: -1...1), // about device Y: +X goes to -Z, right edge away
            y: (s * rel.x / range).clamped(to: -1...1) // about device X: +Y comes to +Z, bottom edge away
        )
        let k = 1 - exp(-dt / recenter)
        b = Quaternion(
            w: b.w + (cur.w - b.w) * k, x: b.x + (cur.x - b.x) * k,
            y: b.y + (cur.y - b.y) * k, z: b.z + (cur.z - b.z) * k
        )
        let n = b.dot(b).squareRoot()
        base = n > 0 ? Quaternion(w: b.w / n, x: b.x / n, y: b.y / n, z: b.z / n) : b
        return tilt
    }
}

private extension Double {
    func clamped(to r: ClosedRange<Double>) -> Double { Swift.min(Swift.max(self, r.lowerBound), r.upperBound) }
}
