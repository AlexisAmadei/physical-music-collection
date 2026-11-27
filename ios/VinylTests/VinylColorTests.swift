import Testing
@testable import Vinyl

/// Port of the Android `VinylColorTest`, same cases.
@MainActor
struct VinylColorTests {
    let language = Language.pinned(.french)

    @Test func labelsAreTheFrenchNamesInFrench() {
        #expect(VinylColor.allCases.map { $0.label(in: language) } == [
            "Rouge", "Orange", "Jaune", "Vert", "Bleu", "Violet", "Rose", "Blanc", "Transparent",
            "Or", "Argent", "Gris", "Marron", "Bleu canard", "Os", "Noir",
        ])
    }

    @Test func labelsAreTheEnglishNamesInEnglish() {
        language.select(.english)
        #expect(VinylColor.allCases.map { $0.label(in: language) } == [
            "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink", "White", "Clear",
            "Gold", "Silver", "Grey", "Brown", "Teal", "Bone", "Black",
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

    @Test func coverIsReadWithTheFinishAndSecondColorInBothLanguages() {
        var draft = Draft(title: "Currents", artist: "Tame Impala", year: 2015, format: .vinyl, vinylColor: .red)
        draft.pickFinish(.marble)
        draft.secondColor = .black
        let disc = Disc(draft)
        #expect(disc.coverLabel(in: language) == "Currents, Tame Impala, Vinyle couleur rouge marbré noir, 2015")

        language.select(.english)
        #expect(disc.coverLabel(in: language) == "Currents, Tame Impala, red marble vinyl with black, 2015")

        // A Finish with no Second color reads without one.
        var glitter = draft
        glitter.pickFinish(.glitter)
        #expect(Disc(glitter).coverLabel(in: language) == "Currents, Tame Impala, red glitter vinyl, 2015")
        language.select(.french)
        #expect(Disc(glitter).coverLabel(in: language) == "Currents, Tame Impala, Vinyle couleur rouge pailleté, 2015")
    }

    @Test func aCDOrASolidDiscReadsNoFinish() {
        var draft = Draft(title: "Currents", format: .vinyl, vinylColor: .red)
        draft.pickFinish(.marble)
        draft.format = .cd
        #expect(Disc(draft).coverLabel(in: language) == "Currents, CD")
        draft.format = .vinyl
        draft.pickFinish(nil)
        #expect(Disc(draft).coverLabel(in: language) == "Currents, Vinyle couleur rouge")
    }

    @Test func finishLineIsTheFinishAndColorsInBothLanguages() {
        var draft = Draft(format: .vinyl, vinylColor: .red)
        draft.pickFinish(.marble)
        draft.secondColor = .black
        #expect(Disc(draft).finishLine(in: language) == "Marbré · Rouge et noir")
        draft.secondColor = .teal
        #expect(Disc(draft).finishLine(in: language) == "Marbré · Rouge et bleu canard")
        language.select(.english)
        #expect(Disc(draft).finishLine(in: language) == "Marble · Red and teal")

        draft.pickFinish(.glitter)
        #expect(Disc(draft).finishLine(in: language) == "Glitter · Red")
    }

    @Test func finishLineIsNilForSolidCDAndUncoloredDiscs() {
        #expect(Disc(Draft(format: .vinyl, vinylColor: .red)).finishLine(in: language) == nil)
        #expect(Disc(Draft(format: .vinyl)).finishLine(in: language) == nil)
        var draft = Draft(format: .vinyl, vinylColor: .red)
        draft.pickFinish(.splatter)
        draft.format = .cd
        #expect(Disc(draft).finishLine(in: language) == nil)
    }

    @Test func onlyLightWaxGetsDarkGrooves() {
        let light = Set(VinylColor.allCases.filter { $0.light })
        #expect(light == [.yellow, .white, .clear, .silver, .bone])
    }

    @Test func newColorsComeAfterTodaysNineSoStoredValuesAreStable() {
        #expect(VinylColor.allCases.map(\.rawValue) == [
            "RED", "ORANGE", "YELLOW", "GREEN", "BLUE", "PURPLE", "PINK", "WHITE", "CLEAR",
            "GOLD", "SILVER", "GREY", "BROWN", "TEAL", "BONE", "BLACK",
        ])
    }

    @Test func blackIsOnlyASecondColorAndClearIsOnlyAVinylColor() {
        #expect(!VinylColor.firstChoices.contains(.black))
        #expect(VinylColor.secondChoices.contains(.black))
        #expect(VinylColor.firstChoices.contains(.clear))
        #expect(!VinylColor.secondChoices.contains(.clear))
        #expect(VinylColor.firstChoices.count == 15)
        #expect(VinylColor.secondChoices.count == 15)
    }

    @Test func colorBandOnlyOnColoredVinyl() {
        #expect(Disc(Draft(format: .vinyl, vinylColor: .red)).hasColorBand)
        #expect(!Disc(Draft(format: .vinyl)).hasColorBand)
        // A CD keeps its hidden Vinyl color, but shows no band.
        #expect(!Disc(Draft(format: .cd, vinylColor: .red)).hasColorBand)
    }
}
