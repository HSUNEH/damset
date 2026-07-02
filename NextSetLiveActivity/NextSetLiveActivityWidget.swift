#if os(iOS) && canImport(ActivityKit) && canImport(WidgetKit) && canImport(SwiftUI)
import ActivityKit
import SwiftUI
import WidgetKit

struct NextSetLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NextSetActivityAttributes.self) { context in
            lockScreenView(context: context)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.exerciseName).font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Set \(context.state.currentSetIndex)/\(context.state.totalPlannedSets)")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    lockScreenView(context: context)
                }
            } compactLeading: {
                Text("\(context.state.currentSetIndex)/\(context.state.totalPlannedSets)")
            } compactTrailing: {
                Text("\(context.state.actualReps)")
            } minimal: {
                Image(systemName: "figure.strengthtraining.traditional")
            }
        }
    }

    private func lockScreenView(context: ActivityViewContext<NextSetActivityAttributes>) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(context.state.exerciseName).font(.headline)
                Spacer()
                Text("Set \(context.state.currentSetIndex)/\(context.state.totalPlannedSets)").font(.subheadline)
            }
            HStack(spacing: 28) {
                Button(intent: AdjustRepsIntent(delta: -1)) { Image(systemName: "minus.circle.fill") }
                Text("\(context.state.actualReps)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Button(intent: AdjustRepsIntent(delta: 1)) { Image(systemName: "plus.circle.fill") }
                Button(intent: CompleteSetIntent()) { Text("Done") }
                    .buttonStyle(.borderedProminent)
            }
            if context.state.restRemainingSeconds > 0 {
                Text("Rest \(format(seconds: context.state.restRemainingSeconds))")
                    .font(.headline.monospacedDigit())
            }
        }
        .padding()
    }

    private func format(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
#endif
