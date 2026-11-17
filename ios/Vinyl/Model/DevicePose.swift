import simd

/// Reads motion samples (attitude quaternion + gravity in the device frame, in g) as device → world poses for the
/// `TiltTracker`. Core Motion does not document which way its attitude turns, so the way is learned from gravity
/// (world gravity is straight down in a Z-vertical reference frame) as soon as the phone is off flat, then kept.
/// Until then, `pose` is nil: flat, both ways predict the same gravity.
struct DevicePose {
    /// nil until learned. true: the attitude is device → world as is.
    private(set) var attitudeIsDeviceToWorld: Bool?

    mutating func pose(attitude q: Quaternion, gravity: SIMD3<Double>) -> Quaternion? {
        if attitudeIsDeviceToWorld == nil {
            let down = SIMD3<Double>(0, 0, -1)
            // Device → world q: gravity in the device frame is world down turned back by q.
            let ifDeviceToWorld = simd_distance(q.conjugate.rotate(down), gravity)
            let ifWorldToDevice = simd_distance(q.rotate(down), gravity)
            if abs(ifDeviceToWorld - ifWorldToDevice) > 0.3 {
                attitudeIsDeviceToWorld = ifDeviceToWorld < ifWorldToDevice
            }
        }
        guard let deviceToWorld = attitudeIsDeviceToWorld else { return nil }
        return deviceToWorld ? q : q.conjugate
    }
}

extension Quaternion {
    /// `v` turned by this unit quaternion: q v q*.
    func rotate(_ v: SIMD3<Double>) -> SIMD3<Double> {
        let r = self * Quaternion(w: 0, x: v.x, y: v.y, z: v.z) * conjugate
        return SIMD3(r.x, r.y, r.z)
    }
}
