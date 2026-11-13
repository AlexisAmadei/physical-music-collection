# Vinyl collection

A personal app to keep track of the physical records (vinyl and CD) someone owns or wants.

## Records

**Disc**:
One physical release (an album on vinyl or CD) as the user knows it: title, artist, year, format, rating, comment.
_Avoid_: Record, album, item

**Format**:
The physical medium of a Disc: vinyl or CD. Anything else (cassette, file, DVD) is out of scope.
_Avoid_: Media, type

**Collection**:
The Discs the user owns.
_Avoid_: Library, shelf

**Wishlist**:
The Discs the user wants but does not own yet.
_Avoid_: Wantlist

**Draft**:
A Disc being added or edited, not yet saved.

## Catalog

**Catalog**:
The outside knowledge of existing releases the app asks to prefill a Draft, by barcode or by text.
_Avoid_: Database, API, lookup

**Source**:
One provider the Catalog asks (Discogs, MusicBrainz). Sources are asked in a fixed order; the first one with an answer wins.
_Avoid_: Provider, backend

**Pressing**:
One of many releases of the same album in the same Format. The Catalog shows one Pressing per album and Format.
_Avoid_: Edition, variant
