import Foundation

/// One general, food-first wellness idea derived deterministically from an out-of-range marker.
struct GeneralTip: Identifiable {
    let id: String
    let title: String     // e.g. "Vitamin D — below range"
    let body: String      // educational, non-directive, food-first
    let foods: [String]   // example foods (may be empty)
    let icon: String      // SF Symbol
    let isHigh: Bool      // tints the card (high = red, low = amber)
}

/// Deterministic GENERAL wellness education from a marker's already-computed status.
///
/// IMPORTANT (SPEC §2): these are NOT supplement suggestions — those go through server-side
/// interaction screening (§2.4). These are general dietary/lifestyle education (§2.1), always
/// "discuss with your provider", shown so the plan still offers something useful when no
/// screened supplement maps. Critical markers are excluded here (§2.3) and never get a tip.
/// The app never decides high/low — it only maps a status the engine already computed (§2.2).
enum MarkerGuidance {
    static func tips(for markers: [Marker]) -> [GeneralTip] {
        var out: [GeneralTip] = []
        var seen = Set<String>()
        for m in markers {
            // Only non-critical, out-of-range markers.
            guard m.computedStatus == .low || m.computedStatus == .high else { continue }
            let high = m.computedStatus == .high
            let key = m.nameStd ?? Self.fallbackKey(m.nameRaw)
            guard let copy = Self.copy(key: key, high: high) else { continue }
            // De-dupe by marker key + direction (a panel can repeat names).
            let dedup = "\(key)-\(high)"
            if seen.contains(dedup) { continue }
            seen.insert(dedup)
            out.append(GeneralTip(
                id: m.id,
                title: "\(Self.display(m)) — \(high ? "above range" : "below range")",
                body: copy.body, foods: copy.foods, icon: copy.icon, isHigh: high))
        }
        return out
    }

    private static func display(_ m: Marker) -> String {
        m.nameRaw.isEmpty ? (m.nameStd ?? "Marker") : m.nameRaw
    }

    /// Best-effort normalization when the server didn't standardize the name.
    private static func fallbackKey(_ raw: String) -> String {
        raw.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    private struct Copy { let body: String; let foods: [String]; let icon: String }

    // swiftlint:disable cyclomatic_complexity
    private static func copy(key: String, high: Bool) -> Copy? {
        switch (key, high) {
        case ("vitamin_d_25oh", false), ("vitamin d", false):
            return Copy(body: "Below the typical range. Sunlight and a few foods can help — ask your provider whether a vitamin D supplement is right for you.",
                        foods: ["Salmon", "Sardines", "Egg yolks", "Fortified milk & cereal"], icon: "sun.max.fill")
        case ("vitamin_b12", false):
            return Copy(body: "Below range. B12 comes mostly from animal foods — if you eat little or none, fortified foods or a supplement may help. Discuss with your provider.",
                        foods: ["Eggs", "Dairy", "Fish & meat", "Fortified nutritional yeast"], icon: "bolt.heart.fill")
        case ("folate", false):
            return Copy(body: "Below range. Folate is rich in plants — a varied diet usually helps. Discuss with your provider, especially if pregnant or planning to be.",
                        foods: ["Leafy greens", "Lentils & beans", "Citrus", "Fortified grains"], icon: "leaf.fill")
        case ("ferritin", false), ("iron", false), ("hemoglobin", false), ("hematocrit", false):
            return Copy(body: "Iron stores look low. Iron-rich foods paired with vitamin C improve absorption. Low iron has many causes — please discuss with your provider.",
                        foods: ["Lean red meat", "Lentils", "Spinach", "Pumpkin seeds + citrus"], icon: "drop.fill")
        case ("magnesium", false):
            return Copy(body: "Below range. Magnesium is widespread in whole foods. Discuss with your provider before supplementing, especially with kidney concerns.",
                        foods: ["Leafy greens", "Nuts", "Seeds", "Whole grains"], icon: "leaf.fill")
        case ("calcium", false):
            return Copy(body: "Below range. Dairy, fortified alternatives and greens are good sources. Discuss with your provider.",
                        foods: ["Yogurt & milk", "Fortified plant milk", "Tofu", "Leafy greens"], icon: "cube.fill")
        case ("zinc", false):
            return Copy(body: "Below range. Zinc is found in protein-rich foods. Discuss with your provider.",
                        foods: ["Shellfish", "Meat", "Legumes", "Seeds"], icon: "circle.hexagongrid.fill")
        case ("potassium", false):
            return Copy(body: "Below range. Many fruits and vegetables are rich in potassium. If you have kidney issues, discuss before changing intake.",
                        foods: ["Bananas", "Potatoes", "Beans", "Leafy greens"], icon: "bolt.fill")
        case ("total_cholesterol", true), ("ldl_cholesterol", true):
            return Copy(body: "Above range. Soluble fiber and unsaturated fats may help, alongside regular activity. Discuss a plan with your provider.",
                        foods: ["Oats & barley", "Beans", "Olive oil & nuts", "Fatty fish"], icon: "heart.fill")
        case ("hdl_cholesterol", false):
            return Copy(body: "Below range. Regular movement and healthy fats are commonly suggested. Discuss with your provider.",
                        foods: ["Olive oil", "Fatty fish", "Nuts", "Avocado"], icon: "heart.fill")
        case ("triglycerides", true):
            return Copy(body: "Above range. Cutting added sugar, refined carbs and alcohol — plus omega-3-rich fish and activity — is commonly suggested. Discuss with your provider.",
                        foods: ["Fatty fish", "Fewer sugary drinks", "Whole grains", "Vegetables"], icon: "heart.fill")
        case ("glucose", true), ("hba1c", true):
            return Copy(body: "Above range. Fiber-rich whole foods, fewer sugary drinks and refined carbs, and regular activity are commonly suggested. Please discuss with your provider.",
                        foods: ["Vegetables", "Whole grains", "Beans & lentils", "Water over soda"], icon: "drop.fill")
        case ("crp", true):
            return Copy(body: "Above range — CRP reflects inflammation, which has many causes. An anti-inflammatory eating pattern may help. Please discuss with your provider.",
                        foods: ["Vegetables & fruit", "Fatty fish", "Olive oil", "Whole grains"], icon: "flame.fill")
        case ("alt", true), ("ast", true):
            return Copy(body: "Above range. Liver markers can rise for many reasons; limiting alcohol and a balanced diet may help. Please discuss with your provider.",
                        foods: ["Limit alcohol", "Vegetables & fruit", "Whole grains", "Lean protein"], icon: "cross.case.fill")
        case ("creatinine", true), ("egfr", false):
            return Copy(body: "These are kidney markers. Please discuss with your provider before changing your diet or taking any supplement — some aren't safe with reduced kidney function.",
                        foods: [], icon: "cross.case.fill")
        case ("tsh", _), ("free_t4", _), ("free_t3", _):
            return Copy(body: "This is a thyroid marker. Thyroid results are best interpreted by a clinician — please discuss with your provider.",
                        foods: [], icon: "cross.case.fill")
        case ("sodium", _):
            return Copy(body: "Sodium balance is usually managed with medical guidance and fluids, not supplements. Please discuss with your provider.",
                        foods: [], icon: "cross.case.fill")
        default:
            return nil
        }
    }
    // swiftlint:enable cyclomatic_complexity
}
