# Provenance

A native macOS menu bar app that makes ~/Downloads understandable: it groups files by where they
came from (using the `kMDItemWhereFroms` and `com.apple.quarantine` extended attributes), flags
stale installers and duplicates, and suggests cleanups. Everything stays on-device.

Roadmap and milestone status: @docs/PLAN.md

## Commands
- Test: `scripts/test.sh` (wraps `swift test`; required on Command Line Tools–only machines)
- Run one test: `scripts/test.sh --filter QuarantineParsingTests`
- CLI: `swift run provenance [list|groups|watch] [dir]` (defaults to ~/Downloads)
- App: `scripts/build-app.sh && open build/Provenance.app`
- Format: `swift format format --in-place --recursive Sources Tests` (a hook does this on edit)

## Environment
- No Xcode installed — only Command Line Tools. Never use `xcodebuild` or `.xcodeproj`.
  The app is a SwiftPM executable wrapped into a .app by `scripts/build-app.sh`.
- Dev machine is macOS 15. Deployment target is macOS 15. APIs newer than that
  (e.g. FoundationModels, macOS 26) must be behind `if #available` and be optional features.

## Architecture rules
- `ProvenanceCore` holds all logic and must not import SwiftUI or AppKit. If it can be tested
  without a UI, it belongs in Core.
- `provenance` (CLI) and `ProvenanceApp` are thin shells over Core.
- Swift 6 language mode with strict concurrency. Core types are `Sendable` value types. Don't
  silence concurrency errors with `@unchecked Sendable` or `nonisolated(unsafe)` without asking.
- Tests use Swift Testing (`import Testing`, `@Test`, `#expect`), not XCTest.
- Never modify or delete real user files in tests — use temp directories.

## Safety
- The app must never delete files directly: cleanups move files to the Trash
  (`FileManager.trashItem`), and only after explicit user confirmation.
