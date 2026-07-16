import Charts
import SwiftUI
import DamSetCore

/// Compact, glanceable progress for the exercises completed in one workout.
/// The selected workout is highlighted while the line keeps the surrounding
/// history visible, so an older calendar entry still has useful context.
struct WorkoutProgressChartView: View {
    let selectedSummary: WorkoutSummary
    let allSummaries: [WorkoutSummary]

    @State private var selectedExerciseName: String
    @State private var metric: WorkoutProgressMetric

    init(selectedSummary: WorkoutSummary, allSummaries: [WorkoutSummary]) {
        self.selectedSummary = selectedSummary
        self.allSummaries = allSummaries

        let names = Self.exerciseNames(in: selectedSummary)
        let firstName = names.first ?? ""
        _selectedExerciseName = State(initialValue: firstName)
        _metric = State(initialValue: Self.preferredMetric(
            forExerciseNamed: firstName,
            in: selectedSummary
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            exerciseMenu

            if availableMetrics.count > 1 {
                metricPicker
            }

            if let focusPoint {
                progressSnapshot(focusPoint)
                progressChart
                chartFooter
            } else {
                Text("Complete this exercise again to start its trend.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                    .multilineTextAlignment(.center)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .gymPanel(accent: DamSetDesign.accent.opacity(0.72), cut: 14, padding: 16)
        .onChange(of: selectedExerciseName) { _, _ in
            selectPreferredMetric()
        }
        .onChange(of: exerciseNames) { _, updatedNames in
            guard !updatedNames.contains(selectedExerciseName),
                  let firstName = updatedNames.first else { return }
            selectedExerciseName = firstName
            metric = Self.preferredMetric(forExerciseNamed: firstName, in: selectedSummary)
        }
    }

    private var exerciseMenu: some View {
        Menu {
            ForEach(exerciseNames, id: \.self) { exerciseName in
                Button {
                    selectedExerciseName = exerciseName
                } label: {
                    if exerciseName == selectedExerciseName {
                        Label(exerciseName, systemImage: "checkmark")
                    } else {
                        Text(exerciseName)
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("EXERCISE PROGRESS")
                        .font(.caption2.weight(.bold))
                        .tracking(1.1)
                        .foregroundStyle(DamSetDesign.accent)
                    Text(selectedExerciseName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DamSetDesign.steel)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(DamSetDesign.controlFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DamSetDesign.steelMuted, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Exercise, \(selectedExerciseName)")
        .accessibilityHint("Choose an exercise to show its progress")
    }

    private var metricPicker: some View {
        Picker("Progress metric", selection: $metric) {
            ForEach(availableMetrics, id: \.self) { availableMetric in
                Text(availableMetric.pickerTitle).tag(availableMetric)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private func progressSnapshot(_ point: WorkoutProgressPoint) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                currentValue(point)
                Spacer(minLength: 8)
                trendLabel(point.deltaFromPrevious)
            }
            VStack(alignment: .leading, spacing: 8) {
                currentValue(point)
                trendLabel(point.deltaFromPrevious)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func currentValue(_ point: WorkoutProgressPoint) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("THIS WORKOUT")
                .font(.caption2.weight(.bold))
                .tracking(0.9)
                .foregroundStyle(.secondary)
            Text(valueText(point.value))
                .font(.title2.weight(.black))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
    }

    private func trendLabel(_ delta: Double?) -> some View {
        let presentation = trendPresentation(delta)
        return Label(presentation.text, systemImage: presentation.symbol)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(presentation.color)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var progressChart: some View {
        Chart {
            ForEach(points) { point in
                LineMark(
                    x: .value("Workout date", point.workoutEndTime),
                    y: .value(metric.axisTitle, point.value)
                )
                .foregroundStyle(DamSetDesign.accent)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                PointMark(
                    x: .value("Workout date", point.workoutEndTime),
                    y: .value(metric.axisTitle, point.value)
                )
                .foregroundStyle(point.isSelectedSession ? Color.white : DamSetDesign.accent)
                .symbolSize(point.isSelectedSession ? 115 : 46)
            }

            if let selectedPoint = points.first(where: \.isSelectedSession) {
                RuleMark(x: .value("Selected workout", selectedPoint.workoutEndTime))
                    .foregroundStyle(DamSetDesign.steel.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartYScale(domain: yDomain)
        .chartXScale(range: .plotDimension(startPadding: 26, endPadding: 42))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: min(4, max(2, points.count)))) {
                AxisGridLine().foregroundStyle(DamSetDesign.steelMuted.opacity(0.38))
                AxisTick().foregroundStyle(DamSetDesign.steel)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(DamSetDesign.steel)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine().foregroundStyle(DamSetDesign.steelMuted.opacity(0.38))
                AxisValueLabel {
                    Text(axisValueText(value.as(Double.self) ?? 0))
                }
                .foregroundStyle(DamSetDesign.steel)
            }
        }
        .chartPlotStyle { plot in
            plot
                .background(DamSetDesign.controlFill.opacity(0.52))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .frame(height: 205)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(selectedExerciseName), \(metric.accessibilityTitle) progress chart")
        .accessibilityValue(chartAccessibilitySummary)
    }

    private var chartFooter: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(points.count == 1 ? "First recorded workout — build from here." : "\(points.count) workouts tracked")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            if points.count > 1 {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                    Text("Selected")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(DamSetDesign.steel)
            }
        }
    }

    private var analysis: WorkoutProgressAnalysis {
        WorkoutProgressAnalysis(
            selectedSummary: selectedSummary,
            allSummaries: allSummaries
        )
    }

    private var exerciseNames: [String] {
        let selectedNames = Self.exerciseNames(in: selectedSummary)
        return selectedNames.isEmpty ? analysis.exerciseNames : selectedNames
    }

    private var series: ExerciseProgressSeries? {
        analysis.progress(forExerciseNamed: selectedExerciseName)
    }

    private var availableMetrics: [WorkoutProgressMetric] {
        guard let series else { return [] }
        return WorkoutProgressMetric.allCases.filter { !series.points(for: $0).isEmpty }
    }

    private var points: [WorkoutProgressPoint] {
        series?.points(for: metric) ?? []
    }

    private var focusPoint: WorkoutProgressPoint? {
        points.first(where: \.isSelectedSession) ?? points.last
    }

    private var yDomain: ClosedRange<Double> {
        guard let minimum = points.map(\.value).min(),
              let maximum = points.map(\.value).max() else {
            return 0...1
        }
        let minimumPadding: Double
        switch metric {
        case .weight:
            minimumPadding = 2.5
        case .reps:
            minimumPadding = 1
        case .duration:
            minimumPadding = 5
        }
        let padding = max((maximum - minimum) * 0.18, minimumPadding)
        return max(0, minimum - padding)...(maximum + padding)
    }

    private var chartAccessibilitySummary: String {
        guard let first = points.first, let last = points.last else { return "No recorded values" }
        return "\(points.count) workouts, from \(valueText(first.value)) to \(valueText(last.value))"
    }

    private func valueText(_ value: Double) -> String {
        switch metric {
        case .weight:
            return "\(value.formatted(.number.precision(.fractionLength(0...1)))) kg"
        case .reps:
            return "\(Int(value.rounded())) reps"
        case .duration:
            return Int(value.rounded()).minuteSecondText
        }
    }

    private func axisValueText(_ value: Double) -> String {
        switch metric {
        case .weight:
            return value.formatted(.number.precision(.fractionLength(0...1)))
        case .reps:
            return "\(Int(value.rounded()))"
        case .duration:
            return Int(value.rounded()).minuteSecondText
        }
    }

    private func trendPresentation(_ delta: Double?) -> (text: String, symbol: String, color: Color) {
        guard let delta else {
            return ("First record", "flag.fill", DamSetDesign.steel)
        }
        if delta > 0 {
            return ("+\(valueText(delta)) vs previous", "arrow.up.right", DamSetDesign.moss)
        }
        if delta < 0 {
            return ("−\(valueText(abs(delta))) vs previous", "arrow.down.right", DamSetDesign.amber)
        }
        return ("Same as previous", "equal", DamSetDesign.steel)
    }

    private static func exerciseNames(in summary: WorkoutSummary) -> [String] {
        var names: [String] = []
        var seen = Set<String>()
        for set in summary.completedSets where seen.insert(set.exerciseName).inserted {
            names.append(set.exerciseName)
        }
        return names
    }

    private static func preferredMetric(
        forExerciseNamed exerciseName: String,
        in summary: WorkoutSummary
    ) -> WorkoutProgressMetric {
        let matchingSets = summary.completedSets.filter { $0.exerciseName == exerciseName }
        if matchingSets.contains(where: { $0.trackingMode == .duration }) {
            return .duration
        }
        if matchingSets.contains(where: { $0.exerciseKind == .weighted }) {
            return .weight
        }
        return .reps
    }

    private func selectPreferredMetric() {
        let preferred = Self.preferredMetric(
            forExerciseNamed: selectedExerciseName,
            in: selectedSummary
        )
        if availableMetrics.contains(preferred) {
            metric = preferred
        } else if let firstAvailableMetric = availableMetrics.first {
            metric = firstAvailableMetric
        }
    }
}

private extension WorkoutProgressMetric {
    var axisTitle: String {
        switch self {
        case .weight: "Weight (kg)"
        case .reps: "Reps"
        case .duration: "Time (mm:ss)"
        }
    }

    var pickerTitle: String {
        switch self {
        case .weight: "Best weight"
        case .reps: "Best reps"
        case .duration: "Best time"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .weight: "best weight"
        case .reps: "best repetitions"
        case .duration: "best duration"
        }
    }
}
