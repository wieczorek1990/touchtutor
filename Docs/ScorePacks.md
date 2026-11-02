# Score packs

The app has a StoreKit 2 purchase flow for non-consumable score packs, restoration, transaction updates, and playback access checks. Scores and score packs are defined in TOML configuration files in `Resources/`:

- **`scores_free.toml`** — Free default scores (always included).
- **`scores_test.toml`** — Test scores (included only in DEBUG builds).
- **`score_packs.toml`** — Paid score packs (always included).
- **`score_packs_test.toml`** — Test score packs (included only in DEBUG builds).

The parser in `Sources/TouchTutor/TOMLParser.swift` reads these files at startup. `ScoreItem.defaultScores` loads from `scores_free.toml` (and `scores_test.toml` in DEBUG). `ScorePack.catalog` loads from `score_packs.toml` (and `score_packs_test.toml` in DEBUG).

## Add a free score

1. Add its MusicXML file to `Resources/Scores`.
2. Add a `[[scores]]` entry to `Resources/scores_free.toml` with `id`, `title`, `artist`, and `album`. The MusicXML file must be named `{id}.xml` and placed in `Resources/Scores`.

## Add a paid score pack

1. Add its MusicXML files to `Resources/Scores`.
2. Add a `[[packs]]` entry to `Resources/score_packs.toml` with `id` (the App Store Connect product ID), `title`, `color`, and one or more `[[packs.scores]]` child entries. Each score child only needs `id`. The MusicXML file for each score must be named `{id}.xml`. Use unique score IDs and do not also list paid scores in `scores_free.toml`.
3. Create that product as a **non-consumable** in App Store Connect.

## Add a test score or pack

Add entries to `scores_test.toml` or `score_packs_test.toml` respectively. These are loaded only in DEBUG builds.

## Test purchases

1. Open `TouchTutor.xcodeproj` (rather than `Package.swift`).
2. Select the **TouchTutor** scheme and an iOS simulator, then run with **⌘R**.
3. Open the score-pack store and buy **Practice Pack (Test)**. The scheme already selects `ScorePacks.storekit`, which simulates purchases locally without charging you.
4. Confirm that both practice scores become playable and display open-lock icons. Cancel a purchase to check that they stay locked.
5. Use **Debug → StoreKit → Manage Transactions** to simulate a refund, or delete the transaction and relaunch to repeat a purchase. Also check relaunch and Restore Purchases.

Edit test products by selecting `ScorePacks.storekit` in the project navigator. To change or disable the configuration, use **Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration**. The local configuration applies to Run, including when Run uses Release; it is not bundled into archived apps.

Run the unit tests with **⌘U**; the shared scheme includes `TouchTutorTests`.

## Configure additional packs

See the **Add a paid score pack** section above for the TOML-based workflow. The steps below supplement it with App Store Connect and distribution details.

1. Create the product as a **non-consumable** in App Store Connect. Set its price, localized metadata, availability, and review information there. The app displays StoreKit's localized price; it does not hardcode prices.
2. The app target includes the In-App Purchase capability. Configure distribution signing for it.
3. Test through a StoreKit configuration in Xcode, then Sandbox/TestFlight, before submitting the product and app.

Apple references: [StoreKit](https://developer.apple.com/documentation/storekit), [universal purchase](https://developer.apple.com/support/universal-purchase/).

## Validate purchases

Exercise successful purchase, cancellation, failure, Ask to Buy approval, relaunch, restore on another device, refunds, unavailable products, and offline access after an earlier purchase. Verify every playback entry point, including keyboard commands and double-clicks, respects ownership.

Unit tests use a commerce test double to cover ownership transitions and playback protection. They do not replace StoreKit Sandbox testing or App Store Connect configuration.

## Imported scores

Imports are copied into Application Support/TouchTutor/ImportedScores and indexed in library.json. The index stores stable IDs and names; file locations are resolved relative to the library folder. Imports remain available after relaunch or after the original is moved or deleted. Deleting an import removes its library entry and attempts to remove the owned copy, leaving the original alone. This is local persistence, not iCloud synchronization.

Older versions did not save an import index, so previously forgotten imports must be imported again.

## Generate TOML score entries

Run the Python script with a score file to print a TOML `[[scores]]` entry:

```sh
python3 bin/score_metadata.py "Resources/Scores/zanarkand.xml"
```

The script emits `id`, `title`, `artist`, and `album` as a TOML table entry. Paste it into the appropriate TOML file (`scores_free.toml`, `scores_test.toml`, or `score_packs.toml`). Add the display strings to the localization file when translating them.

The title comes from the MusicXML work title, then movement title, then filename. The ID comes from the filename. Rename the MusicXML file to `{id}.xml` and place it in `Resources/Scores`. Edit the generated fields as needed. The script takes one uncompressed MusicXML file and prints TOML to stdout; Python 3 and its standard library are sufficient. For the app, use a bundled `.xml` file.

Run script tests with `python3 -B -m unittest discover -s Tests/Python -v`.
