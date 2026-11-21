import Testing
@testable import Vinyl

/// Port of the Android `VinylColorTest`, same cases.
struct VinylColorTests {
    @Test func onlyLightWaxGetsDarkGrooves() {
        let light = Set(VinylColor.allCases.filter { $0.light })
        #expect(light == [.yellow, .white, .clear])
    }

    @Test func colorBandOnlyOnColoredVinyl() {
        #expect(Disc(Draft(format: .vinyl, vinylColor: .red)).hasColorBand)
        #expect(!Disc(Draft(format: .vinyl)).hasColorBand)
        // A CD keeps its hidden Vinyl color, but shows no band.
        #expect(!Disc(Draft(format: .cd, vinylColor: .red)).hasColorBand)
    }
}
