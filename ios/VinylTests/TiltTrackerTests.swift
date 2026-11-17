import Foundation
import Testing
@testable import Vinyl

/// Port of the Android `TiltTrackerTest`, same cases and tolerances.
struct TiltTrackerTests {
    /// Unit quaternion for `deg` degrees about the unit axis (ax, ay, az).
    private func q(_ deg: Double, _ ax: Double, _ ay: Double, _ az: Double) -> Quaternion {
        let h = deg * .pi / 180 / 2
        let s = sin(h)
        return Quaternion(w: cos(h), x: ax * s, y: ay * s, z: az * s)
    }

    /// `b` applied after `a`: b · a.
    private func then(_ a: Quaternion, _ b: Quaternion) -> Quaternion {
        Quaternion(
            w: b.w * a.w - b.x * a.x - b.y * a.y - b.z * a.z,
            x: b.w * a.x + b.x * a.w + b.y * a.z - b.z * a.y,
            y: b.w * a.y - b.x * a.z + b.y * a.w + b.z * a.x,
            z: b.w * a.z + b.x * a.y - b.y * a.x + b.z * a.w
        )
    }

    private func isFlat(_ t: Tilt) -> Bool {
        abs(t.x) <= 1e-5 && abs(t.y) <= 1e-5
    }

    private func near(_ a: Double, _ b: Double, _ tolerance: Double) -> Bool {
        abs(a - b) <= tolerance
    }

    /// Phone held up at 55°: any pose works as zero.
    private var hold: Quaternion { q(55, -1, 0, 0) }
    private let dt = 0.02

    @Test func firstSampleIsFlat() {
        var t = TiltTracker()
        #expect(isFlat(t.update(hold, dt: dt)))
    }

    @Test func halfRangeTurnGivesHalfTilt() {
        var t = TiltTracker()
        _ = t.update(hold, dt: dt)
        let r = t.update(then(q(7.5, 0, 1, 0), hold), dt: dt) // twist about device Y
        #expect(near(r.x, 0.5, 0.02))
        #expect(near(r.y, 0, 0.02))
        var t2 = TiltTracker()
        _ = t2.update(hold, dt: dt)
        let r2 = t2.update(then(q(-7.5, 1, 0, 0), hold), dt: dt) // tip about device X
        #expect(near(r2.x, 0, 0.02))
        #expect(near(r2.y, -0.5, 0.02))
    }

    @Test func clampsPastRange() {
        var t = TiltTracker()
        _ = t.update(hold, dt: dt)
        #expect(t.update(then(q(40, 0, 1, 0), hold), dt: dt).x == 1)
    }

    @Test func heldTiltFadesBackToFlat() {
        var t = TiltTracker()
        _ = t.update(hold, dt: dt)
        let tipped = then(q(10, 0, 1, 0), hold)
        var r = Tilt.zero
        for _ in 0..<Int(20 / dt) { r = t.update(tipped, dt: dt) }
        #expect(near(r.x, 0, 0.01))
    }

    @Test func signFlippedQuaternionIsSamePose() {
        var t = TiltTracker()
        _ = t.update(hold, dt: dt)
        let tipped = then(q(7.5, 0, 1, 0), hold)
        let r = t.update(Quaternion(w: -tipped.w, x: -tipped.x, y: -tipped.y, z: -tipped.z), dt: dt)
        #expect(near(r.x, 0.5, 0.02))
    }

    @Test func resetTakesNewZero() {
        var t = TiltTracker()
        _ = t.update(hold, dt: dt)
        t.reset()
        #expect(isFlat(t.update(then(q(10, 0, 1, 0), hold), dt: dt)))
    }
}
