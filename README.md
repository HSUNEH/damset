# NextSet

NextSet is an iPhone-first workout routine MVP for managing sets, rest timers, and workout records with a lock-screen-friendly training flow.

## Product goal

Build an iPhone SwiftUI app where users can configure a workout routine in the app, then manage live set progress from the iPhone Lock Screen with quick reps adjustment, set completion, rest countdown, and restart cues.

## MVP scope

### In the app

- Configure pre-workout routines
- Set target weight
- Set target reps
- Set rest duration between sets
- Review and save final workout records

### On the Lock Screen / Live Activity

- Show current set target reps
- Adjust actual completed reps with `- / +`
- Mark the set as complete
- Start the rest timer after set completion
- Show remaining rest time and next-set restart time
- Notify the user near rest completion

### Rest completion cue

Target experience:

- 3 seconds before rest ends: `3, 2, 1, horn`
- The cue should be audible while workout music continues, where iOS policy and APIs allow it.
- If iOS lock-screen/background audio constraints prevent the ideal cue, the MVP may fall back to notification sound + haptics while preserving the rest-timer flow.

## Initial platform decision

- iPhone-only iOS app
- SwiftUI-first native Apple design
- iOS 17+ target for Live Activity / ActivityKit exploration
- Apple Watch, iPad, and macOS are deferred

## Design reference

Use Apple’s official design resources and Human Interface Guidelines:

- https://developer.apple.com/design/resources/

## Deferred

- Apple Watch app or Watch-specific controls
- iPad/macOS versions
- Custom routine builder beyond MVP-level setup
- AI coaching
- Diet tracking
- Social features
- Wearable integrations beyond future Apple Watch exploration


## Current implementation scaffold

This repo now contains a testable Swift core plus iOS app/Live Activity source scaffolding:

- `Package.swift` — SwiftPM package for `NextSetCore` and core tests.
- `Sources/NextSetCore/` — routine catalog, planned/completed sets, workout session state, lock-screen state, rest cue policy, summary calculation, and local-store protocol.
- `Sources/NextSetCoreSmoke/` — executable smoke verification for default routines, reps adjustment, set completion, rest transitions, manual session-scoped sets, and audio fallback policy. `XcodeTests/NextSetCoreTests/` keeps XCTest coverage for full Xcode environments.
- `NextSetApp/` — SwiftUI iPhone app shell for routine selection and active workout flow.
- `NextSetLiveActivity/` — ActivityKit/App Intents widget scaffold for Lock Screen `- / +` and set completion actions.
- `docs/design-notes.md` — Apple HIG checklist plus Rest cue and iOS audio behavior test policy.
- `docs/qa-automation.md` — layered QA plan for core tests, Xcode builds, simulator checks, real iPhone install, iPhone Mirroring/QuickTime screen-observed QA, and Lock Screen/Live Activity validation.

### Local verification

The current machine has Apple Command Line Tools but not full Xcode selected, and this CLT install cannot import XCTest, so `xcodebuild` and `swift test` are blocked locally. The verified local gate is:

```bash
swift run NextSetCoreSmoke
ruby -e 'require "yaml"; YAML.load_file("seed.yaml"); puts "seed yaml ok"'
git diff --check
```

After full Xcode is installed/selected, add the iOS app/widget targets in Xcode and run an iPhone simulator or device build for the SwiftUI/ActivityKit shell.
