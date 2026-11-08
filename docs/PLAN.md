# Plan

Status: `[x]` done · `[~]` in progress · `[ ]` not started

1. [x] **Scaffold**: SwiftPM layout (Core / CLI / App), test + bundle scripts, CLAUDE.md, hooks.
2. [ ] **Core scanner**: watch ~/Downloads with FSEvents; build a `DownloadItem` index (origin,
   size, dates, UTType, content hash); group by source host / referrer. Verified via CLI.
3. [ ] **Menu bar UI**: MenuBarExtra window listing groups; Quick Look preview; reveal in Finder.
4. [ ] **Rules & cleanup**: stale DMG/PKG whose app is installed, exact duplicates, old
   archives already extracted. Move to Trash only, with confirmation.
5. [ ] **Smart labels**: suggested names/summaries. NaturalLanguage framework on macOS 15;
   FoundationModels when available (macOS 26+).
6. [ ] **App Intents**: Shortcuts actions ("files from host X", "clean up installers").
7. [ ] **Release**: Developer ID signing, notarization, DMG, GitHub Actions CI.

Design details for each milestone get written here during plan mode, before implementation.
