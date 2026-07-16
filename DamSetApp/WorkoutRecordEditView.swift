import SwiftUI
import DamSetCore

struct WorkoutRecordEditView: View {
    let original: WorkoutSummary
    let onSave: (WorkoutSummary) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var workoutEndTime: Date
    @State private var sets: [EditableCompletedSet]
    @State private var showsSaveFailure = false

    init(summary: WorkoutSummary, onSave: @escaping (WorkoutSummary) -> Bool) {
        original = summary
        self.onSave = onSave
        _workoutEndTime = State(initialValue: summary.workoutEndTime)
        _sets = State(initialValue: summary.completedSets.map(EditableCompletedSet.init))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Routine", value: original.routineName)
                    DatePicker(
                        "Workout date",
                        selection: $workoutEndTime,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } header: {
                    Text("Workout")
                } footer: {
                    Text("Changing the date moves this record on the calendar while keeping its original duration.")
                }

                Section {
                    ForEach($sets) { $set in
                        CompletedSetEditorCard(
                            set: $set,
                            canDelete: sets.count > 1,
                            onDelete: { delete(set.id) }
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    }
                } header: {
                    Text("Completed Sets")
                } footer: {
                    Text("Edit load, reps, or time. Saving recalculates total sets, volume, and every progress graph.")
                }
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(DamSetDesign.screenBackground)
            .navigationTitle("Edit Workout")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
        .tint(DamSetDesign.accent)
        .preferredColorScheme(.dark)
        .gymNavigationChrome()
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .alert("Couldn’t save changes", isPresented: $showsSaveFailure) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your draft is still here. Please try again.")
        }
    }

    private var canSave: Bool {
        !sets.isEmpty &&
        sets.allSatisfy {
            $0.actualWeight.isFinite &&
            (0...EditableCompletedSet.maximumWeight).contains($0.actualWeight) &&
            (0...EditableCompletedSet.maximumReps).contains($0.actualReps) &&
            (0...EditableCompletedSet.maximumDurationSeconds).contains($0.actualDurationSeconds)
        }
    }

    private func delete(_ id: UUID) {
        guard sets.count > 1 else { return }
        withAnimation(.snappy) {
            sets.removeAll { $0.id == id }
        }
    }

    private func save() {
        guard canSave else { return }
        let timeShift = workoutEndTime.timeIntervalSince(original.workoutEndTime)
        let completedSets = sets.map { draft in
            CompletedSet(
                setId: draft.sourceSetId,
                exerciseName: draft.exerciseName,
                exerciseKind: draft.exerciseKind,
                actualWeight: draft.actualWeight,
                actualReps: draft.actualReps,
                completedAt: draft.completedAt.addingTimeInterval(timeShift),
                trackingMode: draft.trackingMode,
                actualDurationSeconds: draft.actualDurationSeconds
            )
        }

        var updated = original.replacingCompletedSets(completedSets)
        updated.workoutStartTime = original.workoutStartTime.addingTimeInterval(timeShift)
        updated.workoutEndTime = workoutEndTime

        guard onSave(updated) else {
            showsSaveFailure = true
            return
        }
        dismiss()
    }
}

private struct CompletedSetEditorCard: View {
    @Binding var set: EditableCompletedSet
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(set.exerciseName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(exerciseDescriptor)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .disabled(!canDelete)
                .accessibilityLabel("Delete completed set")
                .accessibilityHint(canDelete ? "Removes this set from the workout record" : "Delete the workout to remove its final set")
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    loadField
                    primaryMetricField
                }
                VStack(spacing: 12) {
                    loadField
                    primaryMetricField
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var loadField: some View {
        if set.exerciseKind == .weighted {
            VStack(alignment: .leading, spacing: 5) {
                Text("KG")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                TextField(
                    "KG",
                    value: $set.actualWeight,
                    format: .number.precision(.fractionLength(0...1))
                )
                .textFieldStyle(.roundedBorder)
                .monospacedDigit()
                .frame(minHeight: 44)
                .decimalInputKeyboard()
                .onChange(of: set.actualWeight) { _, value in
                    let finiteValue = value.isFinite ? value : 0
                    set.actualWeight = min(
                        max(0, finiteValue),
                        EditableCompletedSet.maximumWeight
                    )
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 5) {
                Text("LOAD")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text("Bodyweight")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
        }
    }

    private var exerciseDescriptor: String {
        let load = set.exerciseKind == .bodyweight ? "Bodyweight" : "Weighted"
        return set.trackingMode == .duration ? "\(load) · Timed" : load
    }

    @ViewBuilder
    private var primaryMetricField: some View {
        switch set.trackingMode {
        case .reps:
            repsField
        case .duration:
            durationField
        }
    }

    private var repsField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("REPS")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            TextField("REPS", value: $set.actualReps, format: .number)
                .textFieldStyle(.roundedBorder)
                .monospacedDigit()
                .frame(minHeight: 44)
                .integerInputKeyboard()
                .onChange(of: set.actualReps) { _, value in
                    set.actualReps = min(
                        max(0, value),
                        EditableCompletedSet.maximumReps
                    )
                }
        }
        .frame(maxWidth: .infinity)
    }

    private var durationField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("TIME (MM:SS)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            DurationEntryField(seconds: $set.actualDurationSeconds)
                .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
    }
}

private extension View {
    @ViewBuilder
    func decimalInputKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    @ViewBuilder
    func integerInputKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.numberPad)
        #else
        self
        #endif
    }
}

private struct EditableCompletedSet: Identifiable {
    static let maximumWeight = 2_000.0
    static let maximumReps = 9_999
    static let maximumDurationSeconds = 86_400

    var id = UUID()
    var sourceSetId: String
    var exerciseName: String
    var exerciseKind: ExerciseKind
    var trackingMode: ExerciseTrackingMode
    var actualWeight: Double
    var actualReps: Int
    var actualDurationSeconds: Int
    var completedAt: Date

    init(_ set: CompletedSet) {
        sourceSetId = set.setId
        exerciseName = set.exerciseName
        exerciseKind = set.exerciseKind
        trackingMode = set.trackingMode
        actualWeight = set.actualWeight
        actualReps = set.actualReps
        actualDurationSeconds = set.actualDurationSeconds
        completedAt = set.completedAt
    }
}

/// A typed time field instead of a seconds-only number field. It accepts
/// either seconds (for example, `90`) or `mm:ss` (for example, `01:30`).
/// The bound record updates as soon as the input becomes valid, so tapping
/// Save while the keyboard is still open never drops a just-entered value.
private struct DurationEntryField: View {
    @Binding private var seconds: Int
    @State private var draft: String
    @FocusState private var isFocused: Bool

    init(seconds: Binding<Int>) {
        _seconds = seconds
        _draft = State(initialValue: seconds.wrappedValue.minuteSecondText)
    }

    var body: some View {
        input
            .textFieldStyle(.roundedBorder)
            .monospacedDigit()
            .focused($isFocused)
            .accessibilityLabel("Actual duration")
            .accessibilityHint("Enter seconds or minutes and seconds")
            .onChange(of: draft) { _, rawValue in
                guard let parsed = durationSeconds(from: rawValue) else { return }
                seconds = parsed
            }
            .onChange(of: seconds) { _, updatedSeconds in
                guard !isFocused else { return }
                draft = updatedSeconds.minuteSecondText
            }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    normalizeDraft()
                }
            }
            .onSubmit(normalizeDraft)
    }

    @ViewBuilder
    private var input: some View {
        #if os(iOS)
        TextField("MM:SS", text: $draft)
            .keyboardType(.numbersAndPunctuation)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFocused = false
                    }
                }
            }
        #else
        TextField("MM:SS", text: $draft)
        #endif
    }

    private func normalizeDraft() {
        guard let parsed = durationSeconds(from: draft) else {
            draft = seconds.minuteSecondText
            return
        }
        seconds = parsed
        draft = parsed.minuteSecondText
    }

    private func durationSeconds(from rawValue: String) -> Int? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let parts = trimmed.split(separator: ":", omittingEmptySubsequences: false)
        let parsed: Int?
        if parts.count == 2,
           let minutes = Int(parts[0]),
           let remainder = Int(parts[1]) {
            parsed = min(max(0, minutes), 1_440) * 60 + min(max(0, remainder), 59)
        } else {
            parsed = Int(trimmed)
        }
        return parsed.map { min(EditableCompletedSet.maximumDurationSeconds, max(0, $0)) }
    }
}
