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
