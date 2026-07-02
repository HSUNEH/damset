import SwiftUI
import NextSetCore

struct RoutineListView: View {
    @State var viewModel: WorkoutViewModel

    var body: some View {
        NavigationStack {
            List(viewModel.catalog.routines) { routine in
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
            .navigationTitle("NextSet")
            .sheet(item: Binding(get: { viewModel.activeSession }, set: { viewModel.activeSession = $0 })) { _ in
                ActiveWorkoutView(viewModel: viewModel)
            }
        }
    }
}
