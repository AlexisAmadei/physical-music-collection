import QuartzCore

/// Calls `onFrame` with each screen frame's timestamp, from `start()` until `stop()` (a `CADisplayLink` on the
/// main run loop). Starting a running loop, or stopping a stopped one, does nothing.
@MainActor
final class FrameLoop: NSObject {
    private let onFrame: @MainActor (CFTimeInterval) -> Void
    private var link: CADisplayLink?

    var isRunning: Bool { link != nil }

    init(onFrame: @escaping @MainActor (CFTimeInterval) -> Void) {
        self.onFrame = onFrame
    }

    func start() {
        guard link == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(frame(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    @objc private func frame(_ link: CADisplayLink) {
        onFrame(link.timestamp)
    }
}
