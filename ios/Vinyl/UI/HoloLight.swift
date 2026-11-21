import CoreMotion
import SwiftUI
import UIKit

/// Phone poses, device → world, with the seconds since the last one. The thin seam over Core Motion: the
/// `TiltTracker` never sees Core Motion.
@MainActor
protocol PoseSource: AnyObject {
    func start(_ onPose: @escaping @MainActor (Quaternion, TimeInterval) -> Void)
    func stop()
}

/// Core Motion device motion (gyro + accelerometer, no compass: the Android game rotation vector). Nothing on the
/// simulator, which has no motion sensors.
@MainActor
final class CoreMotionPoses: PoseSource {
    private let manager = CMMotionManager()

    func start(_ onPose: @escaping @MainActor (Quaternion, TimeInterval) -> Void) {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        var reader = DevicePose()
        var last: TimeInterval?
        manager.deviceMotionUpdateInterval = 1.0 / 60
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { motion, _ in
            guard let motion else { return }
            let a = motion.attitude.quaternion
            let g = motion.gravity
            let time = motion.timestamp
            MainActor.assumeIsolated {
                let attitude = Quaternion(w: a.w, x: a.x, y: a.y, z: a.z)
                guard let pose = reader.pose(attitude: attitude, gravity: SIMD3(g.x, g.y, g.z)) else { return }
                let dt = last.map { min(0.1, time - $0) } ?? 0
                last = time
                onPose(pose, dt)
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}

/// Phone tilt shared by all holo silver (Profile card): one sensor for the app, as on Android.
/// The sensor runs only while something on screen reads it, the app is active and Reduce Motion is off.
@MainActor
@Observable
final class HoloLight {
    static let shared = HoloLight(poses: CoreMotionPoses())

    /// Raw phone tilt, zero at the pose when the sensor starts.
    private(set) var tilt = Tilt.zero
    /// Eased tilt, as a light position for `SilverSheen`.
    private(set) var light = CGPoint.zero

    @ObservationIgnored private let poses: PoseSource
    @ObservationIgnored private var tracker = TiltTracker()
    @ObservationIgnored private var readers = 0
    @ObservationIgnored private var running = false
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    init(poses: PoseSource) {
        self.poses = poses
        let center = NotificationCenter.default
        for name in [
            UIApplication.didBecomeActiveNotification, UIApplication.willResignActiveNotification,
            UIAccessibility.reduceMotionStatusDidChangeNotification,
        ] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.update() }
            })
        }
    }

    /// Something that shows the light appeared. Pair with `removeReader`.
    func addReader() {
        readers += 1
        update()
    }

    func removeReader() {
        readers = max(0, readers - 1)
        update()
    }

    private func update() {
        let wanted = readers > 0 && !UIAccessibility.isReduceMotionEnabled
            && UIApplication.shared.applicationState == .active
        guard wanted != running else { return }
        running = wanted
        if wanted {
            tracker.reset()
            poses.start { [weak self] pose, dt in self?.sample(pose, dt: dt) }
        } else {
            poses.stop()
            tilt = .zero
            light = .zero
        }
    }

    private func sample(_ pose: Quaternion, dt: TimeInterval) {
        let t = tracker.update(pose, dt: dt)
        if t != tilt { tilt = t }
        let k = 1 - exp(-dt / 0.08)
        let next = CGPoint(x: light.x + (t.x - light.x) * k, y: light.y + (t.y - light.y) * k)
        // Still phone: no write, so no redraw.
        if abs(next.x - light.x) + abs(next.y - light.y) > 1e-4 { light = next }
    }
}
