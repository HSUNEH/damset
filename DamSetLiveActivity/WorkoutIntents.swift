#if os(iOS) && canImport(AppIntents) && canImport(ActivityKit)
import AppIntents
import Foundation
import DamSetCore

/// Shared body for Live Activity actions. `LiveActivityIntent` runs perform()
/// in the app process, so the App Group session file, the Live Activity, and
/// the rest-cue notifications are all mutated through the same
/// WorkoutSessionSync pipeline the in-app UI uses.
///
/// The session is refreshed against wall-clock time first: once rest has fully
/// elapsed, the action applies to the set the user is about to perform. Taps
/// during an active rest can still correct the just-finished rep count, but
/// completing a set remains performing-only.
private func performLockScreenAction(allowsRestingCorrection: Bool = false, _ mutate: (WorkoutEngine, inout WorkoutRoutineSession) throws -> Void) async {
    let store = WorkoutSessionSync.sessionStore
    guard var session = (try? store.load()) ?? nil else { return }
    let engine = WorkoutEngine()
    engine.refresh(session: &session)
    let canMutate = session.lockScreenState.phase == .performingSet ||
        (allowsRestingCorrection && session.lockScreenState.phase == .resting)
    guard canMutate else {
        await WorkoutSessionSync.applyDidChange(session)
        return
    }
    do {
        try mutate(engine, &session)
    } catch {
        return
    }
    await WorkoutSessionSync.applyDidChange(session)
}

struct AdjustRepsIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Adjust Reps"
    static let isDiscoverable = false

    @Parameter(title: "Delta") var delta: Int

    init() { self.delta = 0 }
    init(delta: Int) { self.delta = delta }

    func perform() async throws -> some IntentResult {
        await performLockScreenAction(allowsRestingCorrection: true) { engine, session in
            try engine.adjustActualReps(session: &session, delta: delta)
        }
        return .result()
    }
}

struct CompleteSetIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Complete Set"
    static let isDiscoverable = false

    init() {}

    func perform() async throws -> some IntentResult {
        await performLockScreenAction { engine, session in
            try engine.completeCurrentSet(session: &session)
        }
        return .result()
    }
}
#endif
