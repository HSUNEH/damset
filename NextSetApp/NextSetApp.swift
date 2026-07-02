import SwiftUI
import NextSetCore

@main
struct NextSetApp: App {
    var body: some Scene {
        WindowGroup {
            RoutineListView(viewModel: WorkoutViewModel())
        }
    }
}
