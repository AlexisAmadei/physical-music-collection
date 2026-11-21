import Testing
@testable import Vinyl

/// Draft rules of the "Vinyle couleur" switch, driven through the app model like the Draft screen does.
@MainActor
struct DraftVinylColorTests {
    let app: AppModel

    init() throws {
        app = try AppModel.pinned()
        app.newDraft()
        app.draft.title = "Currents"
    }

    @Test func turningColoredVinylOnPicksRougeAndOffMeansBlack() {
        #expect(!app.draft.coloredVinyl)

        app.draft.coloredVinyl = true
        #expect(app.draft.vinylColor == .red)

        app.draft.vinylColor = .blue
        app.draft.coloredVinyl = false
        #expect(app.draft.vinylColor == nil)

        app.saveDraft()
        #expect(app.collection.first?.vinylColor == nil)
        #expect(app.collection.first?.hasColorBand == false)
    }

    @Test func switchingToCDKeepsTheVinylColorHiddenAndSwitchingBackShowsIt() throws {
        app.draft.coloredVinyl = true
        app.draft.vinylColor = .green

        app.draft.format = .cd
        #expect(app.draft.shownVinylColor == nil)
        app.saveDraft()

        let saved = try #require(app.collection.first)
        #expect(saved.vinylColor == .green)
        #expect(!saved.hasColorBand)

        app.edit(saved)
        app.draft.format = .vinyl
        #expect(app.draft.shownVinylColor == .green)
        #expect(app.draft.coloredVinyl)
        app.saveDraft()
        #expect(app.collection.first?.hasColorBand == true)
    }

    @Test func coverIsReadAsTitleArtistAndFormatWithTheVinylColor() throws {
        app.draft.artist = "Tame Impala"
        app.draft.year = 2015
        app.saveDraft()
        #expect(app.collection.first?.coverLabel(in: app.language) == "Currents, Tame Impala, Vinyle, 2015")

        app.edit(try #require(app.collection.first))
        app.draft.coloredVinyl = true
        app.saveDraft()
        #expect(app.collection.first?.coverLabel(in: app.language) == "Currents, Tame Impala, Vinyle couleur rouge, 2015")

        app.edit(try #require(app.collection.first))
        app.draft.format = .cd
        app.saveDraft()
        #expect(app.collection.first?.coverLabel(in: app.language) == "Currents, Tame Impala, CD, 2015")
    }

    @Test func coverOfAnUntitledDiscWithNoArtistIsReadSansTitre() {
        #expect(Disc(Draft(format: .cd)).coverLabel(in: app.language) == "Sans titre, CD")
    }

    @Test func theVinylColorFieldShowsOnVinylDraftsOnly() {
        #expect(app.draft.showsVinylColorField)

        app.draft.format = .cd
        #expect(!app.draft.showsVinylColorField)
    }
}
