import SwiftUI
import NextSetCore

struct ActiveWorkoutView: View {
    @Bindable var viewModel: WorkoutViewModel

    var body: some View {
        if let session = viewModel.activeSession {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text(session.lockScreenState.exerciseName)
                        .font(.title.bold())
                    Text("Set \(session.lockScreenState.currentSetIndex) / \(session.lockScreenState.totalPlannedSets)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    Text("Target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(session.lockScreenState.targetReps)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }

                HStack(spacing: 40) {
                    Button { viewModel.adjustReps(-1) } label: {
                        Image(systemName: "minus")
                            .font(.title.bold())
                            .frame(width: 64, height: 64)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!session.lockScreenState.canDecrementReps)

                    Text("\(session.lockScreenState.actualReps)")
                        .font(.system(size: 44, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .accessibilityLabel("Actual reps")

                    Button { viewModel.adjustReps(1) } label: {
                        Image(systemName: "plus")
                            .font(.title.bold())
                            .frame(width: 64, height: 64)
                    }
                    .buttonStyle(.borderedProminent)
                }

                if session.lockScreenState.phase == .resting || session.lockScreenState.phase == .readyForNextSet {
                    RestStatusView(state: session.lockScreenState)
                    Button("Next Set") { viewModel.advanceToNextSet() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                } else if session.lockScreenState.phase == .completed {
                    Text("Workout saved")
                        .font(.headline)
                } else {
                    Button("Set Done") { viewModel.completeSet() }
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)
                }
            }
            .padding()
        } else {
            ContentUnavailableView("No active workout", systemImage: "figure.strengthtraining.traditional")
        }
    }
}

private struct RestStatusView: View {
    let state: LockScreenState

    var body: some View {
        VStack(spacing: 6) {
            Text("Rest")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(format(seconds: state.restRemainingSeconds))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
            if let resumeAt = state.resumeAt {
                Text("Ready at \(resumeAt.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func format(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
