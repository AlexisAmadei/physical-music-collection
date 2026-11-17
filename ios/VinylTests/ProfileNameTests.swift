import Testing
@testable import Vinyl

/// Profile name rules, tested directly (spec #2, seam 3). Port of the Android `ProfileName` and the "Ton nom" field.
struct ProfileNameTests {
    @Test func profileNameIsTrimmedAndCutTo24Characters() {
        #expect(ProfileName.clean("  Alexis  ") == "Alexis")
        #expect(ProfileName.clean("Jean-Baptiste de la Fontaine") == "Jean-Baptiste de la Font")
        #expect(ProfileName.clean(" \n ") == "")
        // Cut, then trimmed again: the cut leaves no trailing space.
        #expect(ProfileName.clean("Jean-Baptiste de la      Fontaine") == "Jean-Baptiste de la")
    }

    /// While typing, the field stops at 24 characters but keeps spaces: trimming waits for OK.
    @Test func typingStopsAt24CharactersAndKeepsSpaces() {
        #expect(ProfileName.typed("Jean-Baptiste de la Fontaine") == "Jean-Baptiste de la Font")
        #expect(ProfileName.typed("Jean ") == "Jean ")
        #expect(ProfileName.typed(" ") == " ")
        #expect(ProfileName.typed(String(repeating: "a", count: 24)) == String(repeating: "a", count: 24))
    }

    @Test func theCounterShowsTheTypedLengthOutOf24() {
        #expect(ProfileName.counter("") == "0 / 24")
        #expect(ProfileName.counter("Alexis ") == "7 / 24")
    }
}
