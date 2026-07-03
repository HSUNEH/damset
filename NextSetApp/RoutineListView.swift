import SwiftUI
import NextSetCore

struct RoutineListView: View {
    @State var viewModel: WorkoutViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Routines") {
                    ForEach(viewModel.catalog.routines) { routine in
                        Button {
                            viewModel.start(routine)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(routine.routineName)
                                    .font(.headline)
                                Text("\(routine.plannedSets.count) sets")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }

                if !viewModel.savedSummaries.isEmpty {
                    Section("History") {
                        ForEach(viewModel.savedSummaries) { summary in
                            NavigationLink {
                                WorkoutSummaryDetailView(summary: summary)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(summary.routineName)
                                        .font(.headline)
                                    Text(summary.workoutEndTime.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("\(summary.totalSets) sets · \(summary.totalVolume.formatted()) kg")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("NextSet")
            .workoutSessionCover(item: Binding(get: { viewModel.activeSession }, set: { viewModel.activeSession = $0 })) { _ in
                ActiveWorkoutView(viewModel: viewModel)
            }
        }
    }
}

struct WorkoutSummaryDetailView: View {
    let summary: WorkoutSummary

    var body: some View {
        List {
            Section("Sets") {
                ForEach(Array(summary.completedSets.enumerated()), id: \.offset) { index, set in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(set.exerciseName)
                            Text("Set \(index + 1)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(set.actualWeight.formatted()) kg × \(set.actualReps)")
                            .monospacedDigit()
                    }
                }
            }
            Section("Totals") {
                LabeledContent("Total sets", value: "\(summary.totalSets)")
                LabeledContent("Total volume", value: "\(summary.totalVolume.formatted()) kg")
                LabeledContent("Started", value: summary.workoutStartTime.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Ended", value: summary.workoutEndTime.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .navigationTitle(summary.routineName)
        .inlineNavigationTitle()
    }
}
