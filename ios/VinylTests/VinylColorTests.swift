import Testing
@testable import Vinyl

/// Port of the Android `VinylColorTest`, same cases.
struct VinylColorTests {
    @Test func onlyLightWaxGetsDarkGrooves() {
        let light = Set(VinylColor.allCases.filter { $0.light })
        #expect(light == [.yellow, .white, .clear])
    }

    @Test func colorStickerOnlyOnColoredVinyl() {
        #expect(Disc(Draft(format: .vinyl, vinylColor: .red)).hasColorSticker)
        #expect(!Disc(Draft(format: .vinyl)).hasColorSticker)
        // A CD keeps its hidden Vinyl color, but shows no sticker.
        #expect(!Disc(Draft(format: .cd, vinylColor: .red)).hasColorSticker)
    }
}
