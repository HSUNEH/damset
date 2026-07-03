import Foundation

/// Persists the in-flight workout session as ISO-8601 JSON so the app and the
/// Live Activity extension can act on the same state across process boundaries.
public final class ActiveSessionStore: @unchecked Sendable {
    private let fileURL: URL
    private let lock = NSLock()

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// Uses the shared App Group container when the entitlement is present,
    /// falling back to a local path so development builds keep functioning.
    public convenience init(appGroupId: String) {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        self.init(fileURL: base.appendingPathComponent("active-workout-session.json"))
    }

    public func save(_ session: WorkoutRoutineSession) throws {
        lock.lock()
        defer { lock.unlock() }
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        try data.write(to: fileURL, options: .atomic)
    }

    public func load() throws -> WorkoutRoutineSession? {
        lock.lock()
        defer { lock.unlock() }
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        guard !data.isEmpty else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WorkoutRoutineSession.self, from: data)
    }

    public func clear() throws {
        lock.lock()
        defer { lock.unlock() }
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }
}
