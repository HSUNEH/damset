import Foundation
import Observation
import NextSetCore

@Observable
final class WorkoutViewModel {
    private let engine = WorkoutEngine()
    let catalog = RoutineCatalog()
    var activeSession: WorkoutRoutineSession?
    var lastSummary: WorkoutSummary?
    var errorMessage: String?

    func start(_ routine: RoutineTemplate) {
        do {
            activeSession = try engine.startSession(routine: routine)
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

    func completeSet() {
        guard var session = activeSession else { return }
        do {
            try engine.completeCurrentSet(session: &session)
            if session.sessionStatus == .completed {
                lastSummary = engine.summarize(session: session, endedAt: session.workoutEndTime ?? Date())
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
        } catch {
            errorMessage = String(describing: error)
        }
    }
}
