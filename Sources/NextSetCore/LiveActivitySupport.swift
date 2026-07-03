import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

#if os(iOS) && canImport(ActivityKit)
public struct NextSetActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var exerciseName: String
        public var currentSetIndex: Int
        public var totalPlannedSets: Int
        public var targetReps: Int
        public var actualReps: Int
        public var restRemainingSeconds: Int
        public var resumeAt: Date?
        public var phase: String

        public init(exerciseName: String, currentSetIndex: Int, totalPlannedSets: Int, targetReps: Int, actualReps: Int, restRemainingSeconds: Int, resumeAt: Date?, phase: String) {
            self.exerciseName = exerciseName
            self.currentSetIndex = currentSetIndex
            self.totalPlannedSets = totalPlannedSets
            self.targetReps = targetReps
            self.actualReps = actualReps
            self.restRemainingSeconds = restRemainingSeconds
            self.resumeAt = resumeAt
            self.phase = phase
        }

        public init(_ state: LockScreenState) {
            self.init(
                exerciseName: state.exerciseName,
                currentSetIndex: state.currentSetIndex,
                totalPlannedSets: state.totalPlannedSets,
                targetReps: state.targetReps,
                actualReps: state.actualReps,
                restRemainingSeconds: state.restRemainingSeconds,
                resumeAt: state.resumeAt,
                phase: state.phase.rawValue
            )
        }
    }

    public var sessionId: String
    public var routineName: String

    public init(sessionId: String, routineName: String) {
        self.sessionId = sessionId
        self.routineName = routineName
    }
}
#endif

/// Single side-effect pipeline shared by the app and the Live Activity intents:
/// persist the session to the App Group store, keep the Live Activity in sync,
/// and (re)schedule the rest-end cue. Off-iOS the Live Activity and cue calls
/// compile to no-ops so the SwiftPM shell target can type-check callers.
public enum WorkoutSessionSync {
    public static let appGroupId = "group.com.hsuneh.nextset"

    public static func makeSessionStore() -> ActiveSessionStore {
        ActiveSessionStore(appGroupId: appGroupId)
    }

    public static func makeSummaryStore() -> FileWorkoutStore {
        FileWorkoutStore(appGroupId: appGroupId)
    }

    /// Starts the Live Activity for a session, or adopts an existing one after
    /// an app relaunch.
    public static func startLiveActivity(for session: WorkoutRoutineSession) {
        #if os(iOS) && canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let content = ActivityContent(state: NextSetActivityAttributes.ContentState(session.lockScreenState), staleDate: nil)
        if let existing = Activity<NextSetActivityAttributes>.activities.first(where: { $0.attributes.sessionId == session.sessionId }) {
            Task { await existing.update(content) }
            return
        }
        let attributes = NextSetActivityAttributes(sessionId: session.sessionId, routineName: session.routineName)
        _ = try? Activity.request(attributes: attributes, content: content, pushType: nil)
        #endif
    }

    /// Pushes the session's lock-screen state to its Live Activity; ends the
    /// activity when the session is finished.
    public static func updateLiveActivity(for session: WorkoutRoutineSession) async {
        #if os(iOS) && canImport(ActivityKit)
        let content = ActivityContent(state: NextSetActivityAttributes.ContentState(session.lockScreenState), staleDate: nil)
        for activity in Activity<NextSetActivityAttributes>.activities where activity.attributes.sessionId == session.sessionId {
            if session.sessionStatus == .completed || session.sessionStatus == .cancelled {
                await activity.end(content, dismissalPolicy: .default)
            } else {
                await activity.update(content)
            }
        }
        #endif
    }

    public static func endAllLiveActivities() async {
        #if os(iOS) && canImport(ActivityKit)
        for activity in Activity<NextSetActivityAttributes>.activities {
            await activity.end(activity.content, dismissalPolicy: .immediate)
        }
        #endif
    }

    /// Applies every side effect a session mutation requires. Call after each
    /// engine operation, whether it ran in the app or in a Live Activity intent.
    public static func applyDidChange(_ session: WorkoutRoutineSession) async {
        switch session.sessionStatus {
        case .completed:
            let summary = WorkoutEngine().summarize(session: session, endedAt: session.workoutEndTime ?? Date())
            try? makeSummaryStore().save(summary)
            try? makeSessionStore().clear()
            RestCueScheduler.cancelPendingCues()
        case .cancelled:
            try? makeSessionStore().clear()
            RestCueScheduler.cancelPendingCues()
        default:
            try? makeSessionStore().save(session)
            if session.sessionStatus == .resting,
               session.lockScreenState.phase == .resting,
               let resumeAt = session.lockScreenState.resumeAt {
                RestCueScheduler.scheduleRestEndCue(resumeAt: resumeAt, upcomingExercise: upcomingExerciseName(session))
            } else if session.lockScreenState.phase == .performingSet {
                RestCueScheduler.cancelPendingCues()
            }
        }
        await updateLiveActivity(for: session)
    }

    private static func upcomingExerciseName(_ session: WorkoutRoutineSession) -> String? {
        guard session.plannedSets.indices.contains(session.currentSetIndex) else { return nil }
        return session.plannedSets[session.currentSetIndex].exerciseName
    }
}
