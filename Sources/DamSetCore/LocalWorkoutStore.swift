import Foundation

public protocol LocalWorkoutStore: Sendable {
    func save(_ summary: WorkoutSummary) throws
    func summary(sessionId: String) throws -> WorkoutSummary?
    func allSummaries() throws -> [WorkoutSummary]
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

    public func allSummaries() throws -> [WorkoutSummary] {
        summaries.values.sorted { $0.workoutEndTime > $1.workoutEndTime }
    }
}

/// Codable-file persistence used while SwiftData is unavailable in the local toolchain.
/// Summaries are stored as an ISO-8601 JSON array and looked up by sessionId.
public final class FileWorkoutStore: LocalWorkoutStore, @unchecked Sendable {
    private let fileURL: URL
    private let lock = NSLock()

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public convenience init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let url = base
            .appendingPathComponent("DamSet", isDirectory: true)
            .appendingPathComponent("workout-summaries.json")
        self.init(fileURL: url)
    }

    /// Stores summaries in the shared App Group container so both the app and
    /// the Live Activity extension read and write the same history.
    public convenience init(appGroupId: String) {
        guard let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            self.init()
            return
        }
        self.init(fileURL: base.appendingPathComponent("workout-summaries.json"))
    }

    public func save(_ summary: WorkoutSummary) throws {
        lock.lock()
        defer { lock.unlock() }
        var summaries = try load()
        summaries.removeAll { $0.sessionId == summary.sessionId }
        summaries.append(summary)

        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(summaries)
        try data.write(to: fileURL, options: .atomic)
    }

    public func summary(sessionId: String) throws -> WorkoutSummary? {
        lock.lock()
        defer { lock.unlock() }
        return try load().first { $0.sessionId == sessionId }
    }

    public func allSummaries() throws -> [WorkoutSummary] {
        lock.lock()
        defer { lock.unlock() }
        return try load().sorted { $0.workoutEndTime > $1.workoutEndTime }
    }

    private func load() throws -> [WorkoutSummary] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        guard !data.isEmpty else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([WorkoutSummary].self, from: data)
    }
}
