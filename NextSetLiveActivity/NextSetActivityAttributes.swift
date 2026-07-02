#if os(iOS) && canImport(ActivityKit)
import ActivityKit
import Foundation

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
    }

    public var sessionId: String
    public var routineName: String

    public init(sessionId: String, routineName: String) {
        self.sessionId = sessionId
        self.routineName = routineName
    }
}
#endif
