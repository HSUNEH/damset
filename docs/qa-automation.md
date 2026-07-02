# NextSet QA automation plan

NextSet needs more than unit tests because the core product value lives on the iPhone Lock Screen: Live Activity controls, rest timers, haptics/audio, and interaction while music is playing.

## QA layers

### 1. Deterministic core tests

Purpose: verify workout state transitions without UI/device dependencies.

Current local gate:

```bash
swift build
swift run NextSetCoreSmoke
ruby -e 'require "yaml"; YAML.load_file("seed.yaml"); puts "seed yaml ok"'
git diff --check
```

Covers:

- Default routine catalog has at least 3 routines.
- Workout session starts from a routine.
- Actual reps can be adjusted and clamp at zero.
- Completing a set records `CompletedSet` and starts rest.
- Rest reaches ready state and advances to the next set.
- Manual sets are session-scoped and do not mutate reusable routine templates.
- Rest cue fallback is selected when ideal audio cannot preserve music playback.

### 2. Xcode/iOS build gate

Requires full Xcode selected:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -version
```

Then add/run gates:

```bash
xcodebuild -scheme NextSet -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -scheme NextSet -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Purpose:

- Compile the real iOS app target.
- Compile the Widget Extension / Live Activity target.
- Run XCTest/UI tests where available.

### 3. Simulator UI automation

Useful for fast app-shell checks:

- Launch app.
- Pick a routine.
- Adjust reps.
- Complete a set.
- Verify rest view appears.
- Verify final summary after last set.

Limitation: simulator is not sufficient for final Live Activity, Lock Screen, haptic/audio, or music-interruption behavior.

### 4. Real iPhone install + logs

Requires:

- iPhone connected to Mac.
- “Trust This Computer” approved on iPhone.
- iPhone Developer Mode enabled.
- Apple signing team selected in Xcode.

Agent-visible checks:

```bash
xcrun xctrace list devices
xcrun devicectl list devices
```

Then install/run through Xcode or `xcodebuild` once project targets exist.

Purpose:

- Verify real install.
- Capture build/runtime logs.
- Detect crashes.
- Verify Live Activity permissions and behavior.

### 5. Screen-observed QA

The agent cannot see the iPhone screen directly unless the iPhone display is surfaced on the Mac or through an external camera/feed.

Preferred options:

1. **macOS iPhone Mirroring**
   - This Mac has `/System/Applications/iPhone Mirroring.app`.
   - If the mirrored iPhone window is visible on the Mac, the agent can use macOS screenshots to inspect it.
   - Best path for iterative visual QA if it exposes Lock Screen / app states reliably.

2. **QuickTime Player iPhone capture**
   - Connect iPhone by USB.
   - Open QuickTime Player → New Movie Recording → select iPhone as camera source.
   - If the QuickTime window is visible on Mac, the agent can screenshot/analyze the mirrored view.
   - Good fallback when iPhone Mirroring is limited.

3. **External camera pointed at iPhone**
   - Useful if Lock Screen, haptics, or physical-device behavior is not visible via software mirroring.
   - Camera feed must appear on the Mac as a window or capture device the agent can inspect.

### 6. Lock Screen / Live Activity manual-observed test script

Run on real iPhone:

1. Install and launch NextSet.
2. Start music playback in Music/Spotify/YouTube Music.
3. Start a default routine.
4. Lock iPhone.
5. Verify Live Activity shows:
   - exercise name
   - set index
   - target/actual reps
   - `- / +`
   - Set Done
   - rest remaining
   - resume-at time
6. Use `- / +` from Lock Screen and verify app state updates.
7. Tap Set Done and verify rest timer starts.
8. At T-3 seconds, observe cue:
   - ideal pass: `3, 2, 1, horn` is heard and music remains playing.
   - fallback pass: notification sound/haptics happen, music remains acceptable, and fallback reason is documented.
9. Continue until final summary is saved.

## Automation priority

1. Create Xcode project/targets so the app can install.
2. Add CLI build/install gates with `xcodebuild` and `devicectl`.
3. Add screen-observed QA harness using iPhone Mirroring or QuickTime window screenshots.
4. Add real-device checklist runner that records logs, screenshots, and pass/fail notes.
5. Only then tune Live Activity and audio/haptic behavior.

## Current blockers

- Full Xcode is not selected on this Mac; current `xcodebuild` fails because the active developer directory is Command Line Tools.
- Real iPhone build/install requires signing setup and a connected trusted iPhone.
- Final Lock Screen/audio behavior must be verified on physical device.
