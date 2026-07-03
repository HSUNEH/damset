import Foundation
import Observation
import NextSetCore

@Observable
final class WorkoutViewModel {
    private let engine = WorkoutEngine()
    private let store: LocalWorkoutStore
    let catalog = RoutineCatalog()
    var activeSession: WorkoutRoutineSession?
    var lastSummary: WorkoutSummary?
    var savedSummaries: [WorkoutSummary] = []
    var actualWeight: Double = 0
    var errorMessage: String?

    init(store: LocalWorkoutStore = FileWorkoutStore()) {
        self.store = store
        reloadSummaries()
    }

    func start(_ routine: RoutineTemplate) {
        do {
            let session = try engine.startSession(routine: routine)
            activeSession = session
            actualWeight = session.currentPlannedSet?.targetWeight ?? 0
            lastSummary = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func adjustReps(_ delta: Int) {
        guard var session = activeSession else { return }
        do {
            try engine.adjustActualReps(session: &session, delta: delta)
            activeSession = session
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func adjustWeight(_ delta: Double) {
        actualWeight = max(0, actualWeight + delta)
    }

    func completeSet() {
        guard var session = activeSession else { return }
        do {
            try engine.completeCurrentSet(session: &session, actualWeight: actualWeight)
            if session.sessionStatus == .completed {
                let summary = engine.summarize(session: session, endedAt: session.workoutEndTime ?? Date())
                try store.save(summary)
                lastSummary = summary
                reloadSummaries()
            }
            activeSession = session
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func advanceToNextSet() {
        guard var session = activeSession else { return }
        do {
            try engine.advanceToNextSet(session: &session)
            activeSession = session
            actualWeight = session.currentPlannedSet?.targetWeight ?? actualWeight
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func repeatCurrentSet() {
        guard var session = activeSession, let planned = session.currentPlannedSet else { return }
        engine.addSessionScopedSet(
            session: &session,
            exerciseName: planned.exerciseName,
            targetWeight: planned.targetWeight,
            targetReps: planned.targetReps,
            restDurationSeconds: planned.restDurationSeconds
        )
        activeSession = session
    }

    func tick(now: Date = Date()) {
        guard var session = activeSession, session.sessionStatus == .resting else { return }
        engine.updateRest(session: &session, now: now)
        if session != activeSession {
            activeSession = session
        }
    }

    func closeWorkout() {
        activeSession = nil
    }

    private func reloadSummaries() {
        do {
            savedSummaries = try store.allSummaries()
        } catch {
            errorMessage = String(describing: error)
        }
    }
}
