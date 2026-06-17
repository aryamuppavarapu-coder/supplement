import SwiftUI

/// Health-profile intake (SPEC §3.1). Medications + conditions feed the interaction engine.
/// If the user chooses not to disclose, suggestions are withheld and the app says why —
/// that choice is captured explicitly via the disclosure toggles.
struct IntakeView: View {
    @Environment(SessionStore.self) private var session

    @State private var age: Int = 35
    @State private var sex: String = "female"
    @State private var pregnant = false
    @State private var meds: Set<MedicationClass> = []
    @State private var conditions: Set<HealthCondition> = []
    @State private var willDiscloseMeds = true
    @State private var willDiscloseConditions = true
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Form {
                Section("About you") {
                    Picker("Age", selection: $age) {
                        ForEach(13...100, id: \.self) { Text("\($0)").tag($0) }
                    }
                    Picker("Biological sex", selection: $sex) {
                        Text("Female").tag("female")
                        Text("Male").tag("male")
                        Text("Intersex").tag("intersex")
                        Text("Prefer not to say").tag("unknown")
                    }
                    if sex == "female" {
                        Toggle("Currently pregnant", isOn: $pregnant)
                    }
                }

                Section {
                    Toggle("I'll share my medications", isOn: $willDiscloseMeds)
                    if willDiscloseMeds {
                        multiSelect(MedicationClass.allCases, selection: $meds) { $0.display }
                    }
                } header: {
                    Text("Medications")
                } footer: {
                    Text("Used only to screen supplement suggestions for safety. If you skip this, we'll withhold suggestions and tell you why.")
                }

                Section {
                    Toggle("I'll share my conditions", isOn: $willDiscloseConditions)
                    if willDiscloseConditions {
                        multiSelect(HealthCondition.allCases, selection: $conditions) { $0.display }
                    }
                } header: {
                    Text("Diagnosed conditions")
                }

                Section {
                    Button {
                        busy = true
                        Task {
                            await session.saveIntake(
                                profile: .init(age: age, sex: sex, pregnant: pregnant, heightCm: nil, weightKg: nil, goals: nil),
                                medications: Array(meds),
                                conditions: Array(conditions),
                                disclosedMeds: willDiscloseMeds,
                                disclosedConditions: willDiscloseConditions
                            )
                            busy = false
                        }
                    } label: {
                        if busy { ProgressView() } else { Text("Save & continue").frame(maxWidth: .infinity) }
                    }
                    .disabled(busy)
                }
            }
            .navigationTitle("Your health profile")
        }
    }

    private func multiSelect<T: Identifiable & Hashable>(
        _ items: [T], selection: Binding<Set<T>>, label: @escaping (T) -> String
    ) -> some View {
        ForEach(items) { item in
            Button {
                if selection.wrappedValue.contains(item) { selection.wrappedValue.remove(item) }
                else { selection.wrappedValue.insert(item) }
            } label: {
                HStack {
                    Text(label(item)).foregroundStyle(.primary)
                    Spacer()
                    if selection.wrappedValue.contains(item) {
                        Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                    }
                }
            }
        }
    }
}
