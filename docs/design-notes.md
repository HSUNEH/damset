# DamSet design notes

## Apple design source

The UI direction follows Apple's official design entry point:

- https://developer.apple.com/kr/design/

The relevant Apple framing for this MVP:

- Make the app feel integrated with Apple platforms, not like a web view port.
- Use Human Interface Guidelines as the review bar.
- Use Apple design resources, system typography, SF Symbols, native controls, and platform surfaces.
- Keep Lock Screen / Dynamic Island interactions concise and glanceable.

## Product design direction

DamSet should feel like a focused Apple fitness/timer utility:

- **Calm dark workout surface** while training, so bright gym environments and Lock Screen use remain readable.
- **Large rounded numeric typography** for target reps, actual reps, rest timers, and set progress.
- **Card-based hierarchy**: one card for routine choice, one card for current exercise, one card for reps, one card for rest/completion.
- **SF Symbols first** for workout, timer, completion, and adjustment controls.
- **One-hand operation** with primary controls at least 44pt high; actual in-app rep controls are 66pt circular buttons.
- **Native SwiftUI materials and system controls** instead of custom web-style chrome.

## Current visual implementation

Implemented in the app shell:

- `DamSetDesign.swift` centralizes the MVP visual language:
  - dark blue/black app gradient
  - Apple-blue accent
  - mint/orange supporting accents
  - reusable rounded material card treatment
  - routine-specific SF Symbols and tints
- Home screen moved from a plain `List` to a scrollable card layout:
  - hero header
  - routine metric pills
  - routine cards with symbols/tints
  - history cards
- Active workout screen now uses Apple-style cards:
  - workout header card with routine/exercise/set progress
  - 84pt target reps card
  - 50pt actual reps with 66pt circular `- / +` controls
  - weight adjustment card
  - rest card with 64pt countdown
  - completion card
- Live Activity layout refined:
  - icon + exercise + set index header
  - phase pill (`LIVE`, `REST`, `DONE`)
  - rest countdown and ready time
  - always-visible `- / + / Done` lock-screen controls
  - compact Dynamic Island shows set progress and countdown/actual reps

## Apple HIG/UI review checklist

MVP UI reviews must check:

- Native SwiftUI navigation and system controls are used for the workout path.
- Native typography is used; primary workout numbers are at least 34pt.
- SF Symbols/system controls are used where appropriate for `-`, `+`, set completion, timers, and workout symbols.
- Primary action tap targets are at least 44x44pt.
- Core workout state is visible without scrolling on normal iPhone sizes: exercise, set index, target/actual reps, rest time or primary action.
- Accessibility labels exist for rep adjustment, weight adjustment, and set-completion controls.
- Dynamic Type is considered before shipping.
- Dark/light appearance and high-contrast accessibility should be tested on-device.

## Lock Screen control policy

Allowed in Live Activity:

- Adjust actual reps with `- / +`.
- Complete the current set.
- View exercise name, set index, target/actual reps, rest remaining, and resume-at time.

Excluded from Live Activity MVP:

- Weight editing.
- Add/delete set.
- Routine change.
- Rest-duration change.

## Rest cue and iOS audio behavior

Target behavior:

1. Start workout music in another app.
2. Complete a set in DamSet.
3. When rest has 3 seconds left, the cue sequence should be audible as `3, 2, 1, horn`.
4. Music playback should remain playing after the full cue sequence.

Observable ideal pass condition:

- `playbackStateBeforeCue == playing`
- `playbackStateAfterCue == playing`
- cue sequence reaches `countdown3 -> countdown2 -> countdown1 -> horn`

Fallback condition:

- If the ideal sequence interrupts/pauses playback, is blocked by iOS Lock Screen/background policy, or cannot be made reliable on-device, set fallback mode to `notificationSoundAndHaptics` and document the reason in the test result.

Current status: the ActivityKit/UserNotifications path is wired (`RestCueScheduler` notifications for background/locked, `InAppRestCuePlayer` spoken countdown + horn + haptics with audio ducking for foreground). Real-device verification of the music-playback pass condition is still pending; record results in the README "Rest cue and iOS audio behavior" section.
