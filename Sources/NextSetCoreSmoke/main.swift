import Foundation
import NextSetCore

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        FileHandle.standardError.write("Smoke failed: \(message)\n".data(using: .utf8)!)
        exit(1)
    }
}

let catalog = RoutineCatalog()
expect(catalog.routines.count >= 3, "catalog has at least three routines")
expect(catalog.routines.allSatisfy { !$0.plannedSets.isEmpty }, "default routines are non-empty")

let engine = WorkoutEngine()
let routine = catalog.routines[0]
var session = try engine.startSession(routine: routine, now: Date(timeIntervalSince1970: 0), sessionId: "smoke")
expect(session.sessionStatus == .active, "session starts active")
expect(session.lockScreenState.phase == .performingSet, "lock screen starts performing")
expect(session.workoutEndTime == nil, "workoutEndTime is nil while active")

try engine.adjustActualReps(session: &session, delta: -1)
let adjustedReps = session.lockScreenState.actualReps
try engine.completeCurrentSet(session: &session, now: Date(timeIntervalSince1970: 10))
expect(session.completedSets.count == 1, "completing set records one completed set")
expect(session.completedSets[0].actualReps == adjustedReps, "completed set preserves adjusted reps")
expect(session.sessionStatus == .resting, "non-final set starts rest")
expect(session.lockScreenState.resumeAt != nil, "resting state has resumeAt")

if let resumeAt = session.lockScreenState.resumeAt {
    engine.updateRest(session: &session, now: resumeAt)
}
expect(session.lockScreenState.phase == .readyForNextSet, "rest reaches ready state")
try engine.advanceToNextSet(session: &session)
expect(session.currentSetIndex == 2, "advance moves to second set")
expect(session.lockScreenState.phase == .performingSet, "next set returns to performing")

engine.addSessionScopedSet(session: &session, exerciseName: "Lateral Raise", targetWeight: 8, targetReps: 15, restDurationSeconds: 45)
expect(session.plannedSets.last?.manuallyAdded == true, "manual set is session-scoped")
expect(!catalog.routines.flatMap(\.plannedSets).contains { $0.manuallyAdded }, "catalog is not mutated by manual set")

let cue = engine.decideRestCue(playbackWasPlaying: true, playbackStillPlayingAfterCue: false, iOSPolicyAllowsIdealCue: true)
if case .fallbackNotificationAndHaptics(let reason) = cue {
    expect(!reason.isEmpty, "fallback has reason")
} else {
    expect(false, "interrupted playback should choose fallback")
}

print("NextSetCoreSmoke ok")
