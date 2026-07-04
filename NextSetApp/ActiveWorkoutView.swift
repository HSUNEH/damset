import SwiftUI
import Combine
import NextSetCore

struct ActiveWorkoutView: View {
    @Bindable var viewModel: WorkoutViewModel
    @State private var showEndConfirmation = false
    private let restTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Group {
                if let session = viewModel.activeSession {
                    workoutContent(session)
                } else {
                    ContentUnavailableView("No active workout", systemImage: "figure.strengthtraining.traditional")
                }
            }
            .background(NextSetDesign.appGradient.ignoresSafeArea())
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("End", role: .destructive) {
                        if viewModel.activeSession?.sessionStatus == .completed {
                            viewModel.closeWorkout()
                        } else {
                            showEndConfirmation = true
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.repeatCurrentSet()
                    } label: {
                        Label("Add Set", systemImage: "plus")
                    }
                    .disabled(viewModel.activeSession?.sessionStatus == .completed)
                }
            }
            .confirmationDialog("End workout without saving?", isPresented: $showEndConfirmation, titleVisibility: .visible) {
                Button("End Workout", role: .destructive) { viewModel.closeWorkout() }
                Button("Keep Going", role: .cancel) {}
            }
        }
        .tint(NextSetDesign.accent)
        .onReceive(restTimer) { now in
            viewModel.tick(now: now)
        }
    }

    private func workoutContent(_ session: WorkoutRoutineSession) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                workoutHeader(session)
                targetCard(session)
                repsControl(session)

                if session.lockScreenState.phase == .performingSet {
                    weightCard(session)
                    setDoneButton
                } else if session.lockScreenState.phase == .resting || session.lockScreenState.phase == .readyForNextSet {
                    restCard(session.lockScreenState)
                } else if session.lockScreenState.phase == .completed {
                    completionCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
    }

    private func workoutHeader(_ session: WorkoutRoutineSession) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.routineName)
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.62))
                    Text(session.lockScreenState.exerciseName)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                }
                Spacer()
                Text("Set \(session.lockScreenState.currentSetIndex)/\(session.lockScreenState.totalPlannedSets)")
                    .font(.headline.monospacedDigit())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(.thinMaterial, in: Capsule())
                    .foregroundStyle(.white)
            }

            ProgressView(value: progress(for: session))
                .tint(NextSetDesign.mint)
                .accessibilityLabel("Workout progress")
        }
        .nextSetCard(cornerRadius: 30)
    }

    private func targetCard(_ session: WorkoutRoutineSession) -> some View {
        VStack(spacing: 8) {
            Text("TARGET REPS")
                .font(.caption.weight(.semibold))
                .tracking(1)
                .foregroundStyle(.secondary)
            Text("\(session.lockScreenState.targetReps)")
                .font(.system(size: 84, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            if let planned = session.currentPlannedSet {
                Text("\(planned.targetWeight.formatted()) kg × \(planned.targetReps) · \(format(seconds: planned.restDurationSeconds)) rest")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
        .nextSetCard(cornerRadius: 30)
    }

    private func repsControl(_ session: WorkoutRoutineSession) -> some View {
        HStack(spacing: 22) {
            CircleControl(symbol: "minus", label: "Decrease reps") {
                viewModel.adjustReps(-1)
            }
            .disabled(!session.lockScreenState.canDecrementReps)

            VStack(spacing: 4) {
                Text("DID")
                    .font(.caption2.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Text("\(session.lockScreenState.actualReps)")
                    .font(.system(size: 50, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .accessibilityLabel("Actual reps")
            }
            .frame(minWidth: 84)

            CircleControl(symbol: "plus", label: "Increase reps") {
                viewModel.adjustReps(1)
            }
        }
        .frame(maxWidth: .infinity)
        .nextSetCard(cornerRadius: 30)
    }

    private func weightCard(_ session: WorkoutRoutineSession) -> some View {
        HStack(spacing: 16) {
            Button { viewModel.adjustWeight(-2.5) } label: {
                Text("−2.5")
                    .font(.headline.monospacedDigit())
                    .frame(minWidth: 72, minHeight: 48)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.actualWeight <= 0)
            .accessibilityLabel("Decrease weight by 2.5 kilograms")

            VStack(spacing: 3) {
                Text("ACTUAL WEIGHT")
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.actualWeight.formatted()) kg")
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                    .accessibilityLabel("Actual weight")
            }
            .frame(maxWidth: .infinity)

            Button { viewModel.adjustWeight(2.5) } label: {
                Text("+2.5")
                    .font(.headline.monospacedDigit())
                    .frame(minWidth: 72, minHeight: 48)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Increase weight by 2.5 kilograms")
        }
        .nextSetCard(cornerRadius: 26)
    }

    private var setDoneButton: some View {
        Button("Set Done") { viewModel.completeSet() }
            .font(.title3.bold())
            .frame(maxWidth: .infinity, minHeight: 58)
            .buttonStyle(.borderedProminent)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityLabel("Complete current set")
    }

    private func restCard(_ state: LockScreenState) -> some View {
        VStack(spacing: 18) {
            Label("Rest", systemImage: "timer")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(format(seconds: state.restRemainingSeconds))
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            if let resumeAt = state.resumeAt {
                Text("Ready at \(resumeAt.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button("Next Set") { viewModel.advanceToNextSet() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(minHeight: 48)
        }
        .frame(maxWidth: .infinity)
        .nextSetCard(cornerRadius: 30)
    }

    private var completionCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 54))
                .foregroundStyle(.green)
            Text("Workout complete")
                .font(.title2.bold())
            if let summary = viewModel.lastSummary {
                Text("\(summary.totalSets) sets · \(summary.totalVolume.formatted()) kg volume")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Button("Done") { viewModel.closeWorkout() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .nextSetCard(cornerRadius: 30)
    }

    private func progress(for session: WorkoutRoutineSession) -> Double {
        let total = max(session.lockScreenState.totalPlannedSets, 1)
        let completed = min(session.completedSets.count, total)
        return Double(completed) / Double(total)
    }

    private func format(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct CircleControl: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title.bold())
                .frame(width: 66, height: 66)
                .background(NextSetDesign.activeGradient, in: Circle())
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
