#if os(iOS) && canImport(AppIntents)
import AppIntents

struct AdjustRepsIntent: AppIntent {
    static let title: LocalizedStringResource = "Adjust Reps"

    @Parameter(title: "Delta") var delta: Int

    init() { self.delta = 0 }
    init(delta: Int) { self.delta = delta }

    func perform() async throws -> some IntentResult {
        // TODO: route to shared session store / ActivityKit update pipeline.
        .result()
    }
}

struct CompleteSetIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete Set"

    func perform() async throws -> some IntentResult {
        // TODO: route to shared session store / ActivityKit update pipeline.
        .result()
    }
}
#endif
