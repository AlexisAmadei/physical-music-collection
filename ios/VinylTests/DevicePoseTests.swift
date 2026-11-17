import Foundation
import Testing
@testable import Vinyl

/// Reading Core Motion samples as device → world poses for the `TiltTracker`. Core Motion does not document which
/// way its attitude quaternion turns, so `DevicePose` learns it from gravity once the phone is off flat.
struct DevicePoseTests {
    /// Device → world: the phone turned 55° about its X axis, top down (as the TiltTracker tests' hold).
    private let held = Quaternion(w: cos(55 * .pi / 360), x: -sin(55 * .pi / 360), y: 0, z: 0)
    /// Gravity in the device frame for that pose, in g: pulls toward the top edge and the back.
    private let heldGravity = SIMD3(0, 0.819, -0.574)
    /// Flat on a table, turned 30° about the vertical: gravity says nothing about the turn.
    private let flat = Quaternion(w: cos(30 * .pi / 360), x: 0, y: 0, z: sin(30 * .pi / 360))
    private let flatGravity = SIMD3(0.0, 0, -1)

    private func near(_ a: Quaternion?, _ b: Quaternion) -> Bool {
        guard let a else { return false }
        return abs(abs(a.dot(b)) - 1) < 1e-3
    }

    @Test func attitudeAlreadyDeviceToWorldIsKept() {
        var reader = DevicePose()
        #expect(near(reader.pose(attitude: held, gravity: heldGravity), held))
    }

    @Test func attitudeWorldToDeviceIsTurnedAround() {
        var reader = DevicePose()
        #expect(near(reader.pose(attitude: held.conjugate, gravity: heldGravity), held))
    }

    @Test func flatPhoneWaitsUntilGravityTells() {
        var reader = DevicePose()
        #expect(reader.pose(attitude: flat.conjugate, gravity: flatGravity) == nil)
        #expect(near(reader.pose(attitude: held.conjugate, gravity: heldGravity), held))
        // Learned once: back flat, the same way still applies.
        #expect(near(reader.pose(attitude: flat.conjugate, gravity: flatGravity), flat))
    }
}
