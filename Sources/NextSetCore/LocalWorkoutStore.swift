import Foundation

public protocol LocalWorkoutStore: Sendable {
    func save(_ summary: WorkoutSummary) throws
    func summary(sessionId: String) throws -> WorkoutSummary?
}

public final class InMemoryWorkoutStore: LocalWorkoutStore, @unchecked Sendable {
    private var summaries: [String: WorkoutSummary] = [:]

    public init() {}

    public func save(_ summary: WorkoutSummary) throws {
        summaries[summary.sessionId] = summary
    }

    public func summary(sessionId: String) throws -> WorkoutSummary? {
        summaries[sessionId]
    }
}
