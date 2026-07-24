import XCTest
@testable import DamSetCore

final class WorkoutDurationEstimateTests: XCTestCase {
    func testEmptyPlanEstimatesZero() {
        XCTAssertEqual(WorkoutDurationEstimate.estimatedSeconds(for: []), 0)
    }

    func testSingleSetCountsWorkOnly() {
        let sets = [makeSet(id: "a", rest: 90)]
        XCTAssertEqual(WorkoutDurationEstimate.estimatedSeconds(for: sets), 30)
    }

    func testRestAfterFinalSetIsExcluded() {
        let sets = [
            makeSet(id: "a", rest: 90),
            makeSet(id: "b", rest: 60),
            makeSet(id: "c", rest: 120)
        ]
        // 3 × 30 s work + rest after the first two sets only.
        XCTAssertEqual(WorkoutDurationEstimate.estimatedSeconds(for: sets), 90 + 90 + 60)
    }

    func testDurationTrackedSetUsesItsTargetInsteadOfAssumedWork() {
        let hold = PlannedSet(
            setId: "plank",
            exerciseName: "Plank",
            exerciseKind: .bodyweight,
            targetWeight: 0,
            targetReps: 0,
            trackingMode: .duration,
            targetDurationSeconds: 75,
            restDurationSeconds: 60
        )
        let sets = [hold, makeSet(id: "b", rest: 45)]
        XCTAssertEqual(WorkoutDurationEstimate.estimatedSeconds(for: sets), 75 + 60 + 30)
    }

    func testDurationTrackedSetWithoutTargetFallsBackToAssumedWork() {
        let hold = PlannedSet(
            setId: "hang",
            exerciseName: "Dead Hang",
            exerciseKind: .bodyweight,
            targetWeight: 0,
            targetReps: 0,
            trackingMode: .duration,
            targetDurationSeconds: 0,
            restDurationSeconds: 60
        )
        XCTAssertEqual(WorkoutDurationEstimate.estimatedSeconds(for: [hold]), 30)
    }

    func testRoutineTemplateConvenienceMatchesPlannedSetEstimate() throws {
        let routine = try XCTUnwrap(RoutineCatalog.defaultRoutines.first)
        XCTAssertEqual(
            routine.estimatedDurationSeconds,
            WorkoutDurationEstimate.estimatedSeconds(for: routine.plannedSets)
        )
    }

    func testSummaryElapsedSecondsReflectsStartAndEndTimes() throws {
        let engine = WorkoutEngine()
        let start = Date(timeIntervalSince1970: 1_000)
        let routine = try XCTUnwrap(RoutineCatalog.defaultRoutines.first)
        let session = try engine.startSession(routine: routine, now: start)

        let summary = engine.summarize(session: session, endedAt: start.addingTimeInterval(1_930))

        XCTAssertEqual(summary.elapsedSeconds, 1_930)
    }

    func testSummaryElapsedSecondsClampsWhenEndPrecedesStart() throws {
        let engine = WorkoutEngine()
        let start = Date(timeIntervalSince1970: 1_000)
        let routine = try XCTUnwrap(RoutineCatalog.defaultRoutines.first)
        let session = try engine.startSession(routine: routine, now: start)

        let summary = engine.summarize(session: session, endedAt: start.addingTimeInterval(-50))

        XCTAssertEqual(summary.elapsedSeconds, 0)
    }

    private func makeSet(id: String, rest: Int) -> PlannedSet {
        PlannedSet(
            setId: id,
            exerciseName: "Bench Press",
            targetWeight: 60,
            targetReps: 8,
            restDurationSeconds: rest
        )
    }
}
