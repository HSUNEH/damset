#if os(iOS) && canImport(ActivityKit) && canImport(WidgetKit) && canImport(SwiftUI)
import ActivityKit
import SwiftUI
import WidgetKit
import DamSetCore

@main
struct DamSetWidgetBundle: WidgetBundle {
    var body: some Widget {
        DamSetLiveActivityWidget()
    }
}

/// Wood-on-iron palette for the Lock Screen: warm oak accents on the black
/// activity background, tuned for glanceability mid-workout.
private enum WoodTone {
    static let oak = Color(red: 0.588, green: 0.408, blue: 0.247)
    static let oakBright = Color(red: 0.788, green: 0.616, blue: 0.443)
    static let amber = Color(red: 0.780, green: 0.480, blue: 0.230)
    static let moss = Color(red: 0.518, green: 0.643, blue: 0.333)

}

struct DamSetLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DamSetActivityAttributes.self) { context in
            lockScreenView(context: context)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.exerciseName)
                            .font(.headline)
                            .lineLimit(1)
                        Text("Set \(context.state.currentSetIndex)/\(context.state.totalPlannedSets)")
                            .font(.caption)
                            .foregroundStyle(WoodTone.oakBright)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if isResting(context.state), let resumeAt = context.state.resumeAt {
                        Text(timerInterval: Date.now...max(Date.now, resumeAt), countsDown: true)
                            .font(.title3.bold().monospacedDigit())
                            .foregroundStyle(WoodTone.amber)
                            .frame(maxWidth: 72)
                    } else {
                        Text("\(context.state.actualReps)")
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(WoodTone.oakBright)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    controlsRow(context: context)
                }
            } compactLeading: {
                Text("\(context.state.currentSetIndex)/\(context.state.totalPlannedSets)")
                    .font(.caption2.bold())
                    .foregroundStyle(WoodTone.oakBright)
            } compactTrailing: {
                if isResting(context.state), let resumeAt = context.state.resumeAt {
                    Text(timerInterval: Date.now...max(Date.now, resumeAt), countsDown: true)
                        .monospacedDigit()
                        .foregroundStyle(WoodTone.amber)
                        .frame(maxWidth: 44)
                } else {
                    Text("\(context.state.actualReps)")
                        .monospacedDigit()
                        .foregroundStyle(WoodTone.oakBright)
                }
            } minimal: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(WoodTone.oakBright)
            }
        }
    }

    private func isResting(_ state: DamSetActivityAttributes.ContentState) -> Bool {
        state.phase == LockScreenPhase.resting.rawValue || state.phase == LockScreenPhase.readyForNextSet.rawValue
    }

    /// Lock Screen layout, optimized for the between-sets glance: one line of
    /// context on top, the rest countdown as the loudest element while
    /// resting, and full-size record controls that are always tappable.
    private func lockScreenView(context: ActivityViewContext<DamSetActivityAttributes>) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WoodTone.oakBright)
                Text(context.state.exerciseName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text("Set \(context.state.currentSetIndex)/\(context.state.totalPlannedSets)")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(WoodTone.oak.opacity(0.32), in: Capsule())
                    .foregroundStyle(WoodTone.oakBright)
            }

            if context.state.phase == LockScreenPhase.completed.rawValue {
                Label("Workout complete", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(WoodTone.moss)
                    .frame(maxWidth: .infinity, minHeight: 44)
            } else {
                if isResting(context.state), let resumeAt = context.state.resumeAt {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(timerInterval: Date.now...max(Date.now, resumeAt), countsDown: true)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(WoodTone.amber)
                            .frame(maxWidth: 110)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("rest · ready \(resumeAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("target \(context.state.targetReps) reps")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                controlsRow(context: context)
            }
        }
        .padding(14)
    }

    /// − / did / + / Done — every target ≥44pt so a sweaty thumb can hit it
    /// without unlocking.
    private func controlsRow(context: ActivityViewContext<DamSetActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            Button(intent: AdjustRepsIntent(delta: -1)) {
                Image(systemName: "minus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(WoodTone.oak.opacity(0.38), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Decrease reps")

            VStack(spacing: 0) {
                Text("\(context.state.targetReps)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("did \(context.state.actualReps)")
                    .font(.caption2)
                    .foregroundStyle(WoodTone.oakBright)
                    .monospacedDigit()
            }
            .frame(minWidth: 56)

            Button(intent: AdjustRepsIntent(delta: 1)) {
                Image(systemName: "plus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(WoodTone.oak.opacity(0.38), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Increase reps")

            Button(intent: CompleteSetIntent()) {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(WoodTone.oak, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Complete set")
        }
    }
}
#endif
