# iOS app is native Swift, with no code shared with Android

The iOS app lives in `ios/` and is written in Swift and SwiftUI (iOS 26+). It shares no code with the Android app in `android/`. We considered Kotlin Multiplatform and Flutter. We rejected them because the app is small, its custom look (glass, Profile card, cover wheel) needs each platform's native UI, and keeping a shared layer would cost more than writing things twice. The two apps share their language through `GLOSSARY.md`, not through code, and they stay in lockstep: Android may lead by one release at most.
