import Foundation

/// Predicts how long a workout will take before it starts, so the launch
/// screen can show how each exercise toggle changes today's time budget.
///
/// Every set is assumed to take 30 seconds of work; a duration-tracked set
/// with an explicit target uses that target instead. Rest only counts
/// between sets — the engine completes the session immediately after the
/// final set, so that set's rest never elapses.
public enum WorkoutDurationEstimate {
    public static let assumedSetWorkSeconds = 30

    public static func estimatedSeconds(for plannedSets: [PlannedSet]) -> Int {
        let work = plannedSets.reduce(0) { $0 + workSeconds(for: $1) }
        let rest = plannedSets.dropLast().reduce(0) { $0 + $1.restDurationSeconds }
        return work + rest
    }

    private static func workSeconds(for plannedSet: PlannedSet) -> Int {
        if plannedSet.trackingMode == .duration, plannedSet.targetDurationSeconds > 0 {
            return plannedSet.targetDurationSeconds
        }
        return assumedSetWorkSeconds
    }
}

public extension RoutineTemplate {
    /// See `WorkoutDurationEstimate` for the assumptions behind this value.
    var estimatedDurationSeconds: Int {
        WorkoutDurationEstimate.estimatedSeconds(for: plannedSets)
    }
}
