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

/// Glass mission-card palette for the Lock Screen: quiet, translucent, and
/// checklist-like so DamSet feels like a workout mission pinned over wallpaper.
private enum MissionGlass {
    static let card = Color.white.opacity(0.10)
    static let control = Color.white.opacity(0.16)
    static let stroke = Color.white.opacity(0.18)
    static let primary = Color.white
    static let secondary = Color.white.opacity(0.64)
    static let accent = Color(red: 0.62, green: 0.96, blue: 0.84)
    static let warning = Color(red: 1.0, green: 0.74, blue: 0.38)
    static let completed = Color(red: 0.56, green: 0.95, blue: 0.52)
}

struct DamSetLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DamSetActivityAttributes.self) { context in
            lockScreenView(context: context)
                .activityBackgroundTint(.black.opacity(0.72))
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
                            .foregroundStyle(MissionGlass.accent)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if isResting(context.state), let resumeAt = context.state.resumeAt {
                        Text(timerInterval: Date.now...max(Date.now, resumeAt), countsDown: true)
                            .font(.title3.bold().monospacedDigit())
                            .foregroundStyle(MissionGlass.warning)
                            .frame(maxWidth: 72)
                    } else {
                        Text("\(context.state.actualReps)")
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(MissionGlass.accent)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    controlsRow(context: context)
                }
            } compactLeading: {
                Text("\(context.state.currentSetIndex)/\(context.state.totalPlannedSets)")
                    .font(.caption2.bold())
                    .foregroundStyle(MissionGlass.accent)
            } compactTrailing: {
                if isResting(context.state), let resumeAt = context.state.resumeAt {
                    Text(timerInterval: Date.now...max(Date.now, resumeAt), countsDown: true)
                        .monospacedDigit()
                        .foregroundStyle(MissionGlass.warning)
                        .frame(maxWidth: 44)
                } else {
                    Text("\(context.state.actualReps)")
                        .monospacedDigit()
                        .foregroundStyle(MissionGlass.accent)
                }
            } minimal: {
                Image(systemName: "checklist")
                    .foregroundStyle(MissionGlass.accent)
            }
        }
    }

    private func isResting(_ state: DamSetActivityAttributes.ContentState) -> Bool {
        state.phase == LockScreenPhase.resting.rawValue || state.phase == LockScreenPhase.readyForNextSet.rawValue
    }

    /// Lock Screen layout, optimized as a mission card: remaining rest time on
    /// top, then the actual reps the user did with −/+ correction controls.
    private func lockScreenView(context: ActivityViewContext<DamSetActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checklist")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MissionGlass.accent)
                Text(context.state.exerciseName)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text("Set \(context.state.currentSetIndex)/\(context.state.totalPlannedSets)")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(MissionGlass.card, in: Capsule())
                    .foregroundStyle(MissionGlass.secondary)
            }

            if context.state.phase == LockScreenPhase.completed.rawValue {
                Label("Workout complete", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(MissionGlass.completed)
                    .frame(maxWidth: .infinity, minHeight: 44)
            } else {
                missionStatusRow(context: context)
                controlsRow(context: context)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(MissionGlass.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(MissionGlass.stroke, lineWidth: 1)
                )
        )
    }

    private func missionStatusRow(context: ActivityViewContext<DamSetActivityAttributes>) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(isResting(context.state) ? "남은 시간" : "지금 세트")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MissionGlass.secondary)
                if isResting(context.state), let resumeAt = context.state.resumeAt {
                    Text(timerInterval: Date.now...max(Date.now, resumeAt), countsDown: true)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(MissionGlass.warning)
                } else {
                    Text("Set \(context.state.currentSetIndex)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(MissionGlass.primary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("내가 한 횟수")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(MissionGlass.secondary)
                Text("\(context.state.actualReps)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(MissionGlass.accent)
                Text("target \(context.state.targetReps)")
                    .font(.caption2)
                    .foregroundStyle(MissionGlass.secondary)
                    .monospacedDigit()
            }
        }
    }

    /// − / reps / + / Done — every target ≥44pt so a sweaty thumb can hit it
    /// without unlocking. During rest, Done disappears and −/+ corrects the
    /// just-finished rep count while the countdown keeps running.
    private func controlsRow(context: ActivityViewContext<DamSetActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            Button(intent: AdjustRepsIntent(delta: -1)) {
                Image(systemName: "minus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(MissionGlass.control, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Decrease reps")

            VStack(spacing: 1) {
                Text("\(context.state.actualReps)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(MissionGlass.primary)
                Text("reps")
                    .font(.caption2)
                    .foregroundStyle(MissionGlass.secondary)
            }
            .frame(minWidth: 54)

            Button(intent: AdjustRepsIntent(delta: 1)) {
                Image(systemName: "plus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(MissionGlass.control, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Increase reps")

            if context.state.phase == LockScreenPhase.performingSet.rawValue {
                Button(intent: CompleteSetIntent()) {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(MissionGlass.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Complete set")
            } else {
                Text("자동 다음 세트")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MissionGlass.secondary)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(MissionGlass.control, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
}
#endif
