import Testing
@testable import Vinyl

/// Port of the Android `VinylColorTest`, same cases.
@MainActor
struct VinylColorTests {
    let language = Language.pinned(.french)

    @Test func labelsAreTheFrenchNamesInFrench() {
        #expect(VinylColor.allCases.map { $0.label(in: language) } == [
            "Rouge", "Orange", "Jaune", "Vert", "Bleu", "Violet", "Rose", "Blanc", "Transparent",
        ])
    }

    @Test func labelsAreTheEnglishNamesInEnglish() {
        language.select(.english)
        #expect(VinylColor.allCases.map { $0.label(in: language) } == [
            "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink", "White", "Clear",
        ])
    }

    @Test func formatLabelsFollowTheLanguage() {
        #expect(Format.vinyl.label(in: language) == "Vinyle")
        #expect(Format.cd.label(in: language) == "CD")
        language.select(.english)
        #expect(Format.vinyl.label(in: language) == "Vinyl")
        #expect(Format.cd.label(in: language) == "CD")
    }

    @Test func coverIsReadWithTheVinylColorInBothLanguages() {
        let disc = Disc(Draft(title: "Currents", artist: "Tame Impala", year: 2015, format: .vinyl, vinylColor: .red))
        #expect(disc.coverLabel(in: language) == "Currents, Tame Impala, Vinyle couleur rouge, 2015")

        language.select(.english)
        #expect(disc.coverLabel(in: language) == "Currents, Tame Impala, red vinyl, 2015")
        #expect(Disc(Draft(title: "Currents", format: .vinyl)).coverLabel(in: language) == "Currents, Vinyl")
        #expect(Disc(Draft(format: .cd)).coverLabel(in: language) == "Untitled, CD")
    }

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
