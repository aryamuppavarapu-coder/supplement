import SwiftUI

/// Health-profile intake (SPEC §3.1). Medications + conditions feed the interaction engine.
/// If the user chooses not to disclose, suggestions are withheld and the app says why —
/// that choice is captured explicitly via the disclosure toggles.
struct IntakeView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    /// When true the form is being edited from the Profile tab (pre-filled, dismisses on save)
    /// rather than shown as the onboarding root.
    var isEditing = false

    @State private var age: Int? = nil
    @State private var sex: String = ""
    @State private var customSex: String = ""
    @State private var pregnant = false
    @State private var meds: Set<MedicationClass> = []
    @State private var conditions: Set<HealthCondition> = []
    @State private var willDiscloseMeds = true
    @State private var willDiscloseConditions = true
    @State private var busy = false
    @State private var didPrefill = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    BrandHeader(subtitle: "A few details help us screen suggestions for your safety.")
                        .padding(.top, 8)

                    // ── About you ──────────────────────────────────────────────
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionLabel("About you")

                            HStack {
                                Label("Age", systemImage: "calendar")
                                    .labelStyle(.titleAndIcon)
                                    .font(Theme.rounded(.body, weight: .medium))
                                    .foregroundStyle(Theme.ink)
                                    .tint(Theme.sage)
                                Spacer()
                                Picker("Age", selection: $age) {
                                    Text("Select").tag(Int?.none)
                                    ForEach(13...100, id: \.self) { Text("\($0)").tag(Int?.some($0)) }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .tint(Theme.sageDeep)
                            }

                            Divider().overlay(Theme.sage.opacity(0.25))

                            HStack {
                                Label("Biological sex", systemImage: "person.fill")
                                    .labelStyle(.titleAndIcon)
                                    .font(Theme.rounded(.body, weight: .medium))
                                    .foregroundStyle(Theme.ink)
                                    .tint(Theme.sage)
                                Spacer()
                                Picker("Biological sex", selection: $sex) {
                                    Text("Select").tag("")
                                    Text("Female").tag("female")
                                    Text("Male").tag("male")
                                    Text("Intersex").tag("intersex")
                                    Text("Other").tag("other")
                                    Text("Prefer not to say").tag("unknown")
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .tint(Theme.sageDeep)
                            }

                            if sex == "other" {
                                Divider().overlay(Theme.sage.opacity(0.25))
                                TextField("Describe how you identify", text: $customSex)
                                    .font(Theme.rounded(.body))
                                    .foregroundStyle(Theme.ink)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(Theme.cream, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.sage.opacity(0.35), lineWidth: 1))
                            }

                            if sex == "female" {
                                Divider().overlay(Theme.sage.opacity(0.25))
                                Toggle(isOn: $pregnant) {
                                    Label("Currently pregnant", systemImage: "heart.fill")
                                        .labelStyle(.titleAndIcon)
                                        .font(Theme.rounded(.body, weight: .medium))
                                        .foregroundStyle(Theme.ink)
                                        .tint(Theme.sage)
                                }
                                .tint(Theme.sage)
                            }
                        }
                    }

                    // ── Medications ────────────────────────────────────────────
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionLabel("Medications")

                            Toggle(isOn: $willDiscloseMeds) {
                                Label("I'll share my medications", systemImage: "pills.fill")
                                    .labelStyle(.titleAndIcon)
                                    .font(Theme.rounded(.body, weight: .medium))
                                    .foregroundStyle(Theme.ink)
                                    .tint(Theme.sage)
                            }
                            .tint(Theme.sage)

                            if willDiscloseMeds {
                                Divider().overlay(Theme.sage.opacity(0.25))
                                multiSelect(MedicationClass.allCases, selection: $meds) { $0.display }
                            }

                            Text("Used only to screen supplement suggestions for safety. If you skip this, we'll withhold suggestions and tell you why.")
                                .font(Theme.rounded(.footnote))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }

                    // ── Conditions ─────────────────────────────────────────────
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionLabel("Diagnosed conditions")

                            Toggle(isOn: $willDiscloseConditions) {
                                Label("I'll share my conditions", systemImage: "cross.case.fill")
                                    .labelStyle(.titleAndIcon)
                                    .font(Theme.rounded(.body, weight: .medium))
                                    .foregroundStyle(Theme.ink)
                                    .tint(Theme.sage)
                            }
                            .tint(Theme.sage)

                            if willDiscloseConditions {
                                Divider().overlay(Theme.sage.opacity(0.25))
                                multiSelect(HealthCondition.allCases, selection: $conditions) { $0.display }
                            }
                        }
                    }

                    // Persistent safety disclaimer (SPEC §2.5).
                    DisclaimerBanner()

                    // ── Save ───────────────────────────────────────────────────
                    Button {
                        busy = true
                        Task {
                            let resolvedSex: String? = sex == "other"
                                ? (customSex.isEmpty ? "other" : customSex)
                                : (sex.isEmpty ? nil : sex)
                            await session.saveIntake(
                                profile: .init(age: age, sex: resolvedSex, pregnant: sex == "female" ? pregnant : false, heightCm: nil, weightKg: nil, goals: nil),
                                medications: Array(meds),
                                conditions: Array(conditions),
                                disclosedMeds: willDiscloseMeds,
                                disclosedConditions: willDiscloseConditions
                            )
                            busy = false
                            if isEditing { dismiss() }
                        }
                    } label: {
                        if busy {
                            ProgressView().tint(.white).frame(maxWidth: .infinity)
                        } else {
                            Label(isEditing ? "Save changes" : "Save & continue", systemImage: "leaf.fill")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.aero)
                    .disabled(busy)
                    .padding(.top, 2)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .aeroScreen()
            .navigationTitle("Your health profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isEditing {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }.tint(Theme.sageDeep)
                    }
                }
            }
            .onAppear { prefillIfNeeded() }
        }
        .tint(Theme.accent)
    }

    /// When editing an existing profile, populate the form once from the saved document.
    private func prefillIfNeeded() {
        guard isEditing, !didPrefill, let p = session.profile else { return }
        didPrefill = true
        age = p.profile?.age
        let knownSex: Set<String> = ["female", "male", "intersex", "unknown"]
        if let s = p.profile?.sex, !s.isEmpty {
            if knownSex.contains(s) { sex = s }
            else { sex = "other"; customSex = (s == "other") ? "" : s }
        }
        pregnant = p.profile?.pregnant ?? false
        meds = Set((p.medications ?? []).compactMap { MedicationClass(rawValue: $0) })
        conditions = Set((p.conditions ?? []).compactMap { HealthCondition(rawValue: $0) })
        willDiscloseMeds = p.disclosedMeds ?? true
        willDiscloseConditions = p.disclosedConditions ?? true
    }

    private func multiSelect<T: Identifiable & Hashable>(
        _ items: [T], selection: Binding<Set<T>>, label: @escaping (T) -> String
    ) -> some View {
        VStack(spacing: 8) {
            ForEach(items) { item in
                let isOn = selection.wrappedValue.contains(item)
                Button {
                    if selection.wrappedValue.contains(item) { selection.wrappedValue.remove(item) }
                    else { selection.wrappedValue.insert(item) }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isOn ? Theme.sageDeep : Theme.sage.opacity(0.5))
                        Text(label(item))
                            .font(Theme.rounded(.body, weight: isOn ? .semibold : .regular))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isOn ? Theme.tintFill : LinearGradient(colors: [Theme.surface, Theme.surface], startPoint: .top, endPoint: .bottom))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isOn ? Theme.sage.opacity(0.5) : Theme.sage.opacity(0.22), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
