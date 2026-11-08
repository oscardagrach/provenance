# Plan

Status: `[x]` done · `[~]` in progress · `[ ]` not started

1. [x] **Scaffold**: SwiftPM layout (Core / CLI / App), test + bundle scripts, CLAUDE.md, hooks.
2. [x] **Core scanner**: index, watch, and group ~/Downloads by source. Verified via CLI.
   - `Source`: referrer host > download host > quarantine agent > unknown. Referrer wins
     because download hosts are often CDNs; `blob:` URLs are unwrapped to their site.
   - `DownloadScanner`: top level only (folders/bundles = one item), skips hidden and partial
     downloads, caches folder sizes by folder mtime (deep edits can leave a size stale).
   - `DownloadIndex`: pure value type; `reconcile(with:)` → `IndexDiff`, `groups()`.
   - `DirectoryWatcher`: FSEvents → `AsyncStream<Void>` ticks (coalesced); caller rescans.
   - Hashing for duplicate detection is deferred to milestone 4 (only same-size candidates).
3. [ ] **Menu bar UI**: MenuBarExtra window listing groups; Quick Look preview; reveal in Finder.
4. [ ] **Rules & cleanup**: stale DMG/PKG whose app is installed, exact duplicates, old
   archives already extracted. Move to Trash only, with confirmation.
5. [ ] **Smart labels**: suggested names/summaries. NaturalLanguage framework on macOS 15;
   FoundationModels when available (macOS 26+).
6. [ ] **App Intents**: Shortcuts actions ("files from host X", "clean up installers").
7. [~] **Release**: GitHub Actions CI (done); Developer ID signing, notarization, DMG.

Design details for each milestone get written here during plan mode, before implementation.
