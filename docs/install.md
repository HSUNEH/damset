# NextSet install guide

## Current state

`NextSet.xcodeproj` is generated and ready to open in Xcode. This Mac currently has only Apple Command Line Tools selected, not full Xcode, so direct install is blocked until Xcode is installed and selected.

Verified blocker:

```text
xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance
```

## One-time Mac setup

1. Install Xcode from the App Store.
2. Open Xcode once and accept the license / install additional components.
3. Select full Xcode:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -version
```

4. If Xcode asks for license agreement:

```bash
sudo xcodebuild -license accept
```

## Simulator install/run

After full Xcode is selected:

```bash
cd /Users/sunbot/nextset
xcodebuild -project NextSet.xcodeproj -scheme NextSet -showdestinations
xcodebuild -project NextSet.xcodeproj -scheme NextSet -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Then open `NextSet.xcodeproj` in Xcode, pick an iPhone simulator, and press Run.

## Real iPhone install/run

Prerequisites:

- iPhone connected by USB or visible to Xcode over Wi-Fi.
- iPhone is unlocked.
- “Trust This Computer” accepted on the iPhone.
- Developer Mode enabled on iPhone.
- Xcode Signing & Capabilities has a valid Team selected.

Device checks:

```bash
xcrun xctrace list devices
xcrun devicectl list devices
```

Build/install through Xcode:

1. Open `NextSet.xcodeproj`.
2. Select target `NextSet`.
3. Signing & Capabilities → Team → choose ST/HSUNEH Apple team.
4. Select the connected iPhone as destination.
5. Press Run.

## First QA after install

1. Launch NextSet.
2. Pick a default routine.
3. Verify active workout screen shows exercise, set index, target reps, actual reps, `- / +`, and Set Done.
4. Tap `- / +` and verify actual reps change.
5. Tap Set Done and verify rest state appears.
6. Later, verify Live Activity on real Lock Screen and rest cue behavior with music playing.

## Notes

- `NextSet.xcodeproj` was generated from `project.yml` using XcodeGen.
- Regenerate after editing `project.yml`:

```bash
xcodegen generate
```

- Current local non-Xcode gate remains:

```bash
swift build
swift run NextSetCoreSmoke
ruby -e 'require "yaml"; YAML.load_file("seed.yaml"); puts "seed yaml ok"'
git diff --check
```
