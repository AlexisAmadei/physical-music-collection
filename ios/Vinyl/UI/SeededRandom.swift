import CoreGraphics

/// SplitMix64: a tiny random generator with a fixed seed, so what it draws (brush lines, barcodes) never changes.
struct SeededRandom {
    var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// In 0..<1.
    mutating func nextUnit() -> CGFloat { CGFloat(next() >> 11) / CGFloat(1 << 53) }
    mutating func nextBool() -> Bool { next() >> 63 == 1 }
}
