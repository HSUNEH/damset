# NextSet design notes

## Apple HIG/UI review checklist

MVP UI reviews must check:

- Native SwiftUI navigation and system controls are used for the workout path.
- Native typography is used; primary workout numbers are at least 34pt.
- SF Symbols/system controls are used where appropriate for `-`, `+`, set completion, and workout symbols.
- Primary action tap targets are at least 44x44pt.
- Core workout state is visible without scrolling: exercise, set index, target/actual reps, rest time or primary action.
- Accessibility labels exist for rep adjustment and set-completion controls.
- Dynamic Type is considered before shipping.

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
2. Complete a set in NextSet.
3. When rest has 3 seconds left, the cue sequence should be audible as `3, 2, 1, horn`.
4. Music playback should remain playing after the full cue sequence.

Observable ideal pass condition:

- `playbackStateBeforeCue == playing`
- `playbackStateAfterCue == playing`
- cue sequence reaches `countdown3 -> countdown2 -> countdown1 -> horn`

Fallback condition:

- If the ideal sequence interrupts/pauses playback, is blocked by iOS Lock Screen/background policy, or cannot be made reliable on-device, set fallback mode to `notificationSoundAndHaptics` and document the reason in the test result.

Current status: the ActivityKit/UserNotifications path is wired (`RestCueScheduler` notifications for background/locked, `InAppRestCuePlayer` spoken countdown + horn + haptics with audio ducking for foreground). Real-device verification of the music-playback pass condition is still pending; record results in the README "Rest cue and iOS audio behavior" section.
