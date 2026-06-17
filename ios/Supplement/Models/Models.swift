import Foundation

/// Mirrors @supplement/core `ComputedStatus`. Raw values match the strings Cloud Functions
/// write to Firestore. The app NEVER computes these — it only displays them (SPEC §2.2).
enum MarkerStatus: String, Codable, Sendable {
    case low
    case inRange = "in_range"
    case high
    case criticalLow = "critical_low"
    case criticalHigh = "critical_high"
    case qualitative
    case indeterminate

    var isCritical: Bool { self == .criticalLow || self == .criticalHigh }

    var label: String {
        switch self {
        case .low: return "Low"
        case .inRange: return "In range"
        case .high: return "High"
        case .criticalLow, .criticalHigh: return "Needs attention"
        case .qualitative: return "Result"
        case .indeterminate: return "Confirm"
        }
    }
}

struct Marker: Codable, Identifiable, Sendable {
    var id: String { nameRaw }
    let nameRaw: String
    let nameStd: String?
    let value: Double?
    let unitRaw: String?
    let unitStd: String?
    let refLow: Double?
    let refHigh: Double?
    let refText: String?
    let labFlag: String?
    let computedStatus: MarkerStatus
    let confidence: String
    let needsReview: Bool
    let reviewReasons: [String]
    let explanation: String?
    let foodContext: String?

    enum CodingKeys: String, CodingKey {
        case nameRaw, nameStd, value, unitRaw, unitStd, refLow, refHigh, refText, labFlag
        case computedStatus, confidence, needsReview, reviewReasons, explanation, foodContext
    }
}

enum ReportStatus: String, Codable, Sendable {
    case uploaded, extracted, confirmed, analyzed
    case clinicalPending = "clinical_pending"
    case clinicalReleased = "clinical_released"
    case error
}

struct Report: Codable, Identifiable, Sendable {
    let id: String
    var status: ReportStatus
    var labName: String?
    var reportDate: String?
    var hasCritical: Bool
    var criticalMarkers: [String]
    var overallSummary: String?
    var needsHumanReview: Bool
}

struct PlanItem: Codable, Identifiable, Sendable {
    var id: String { nutrient }
    let nutrient: String
    let fromMarker: String?
    let decision: String           // allow | warn | suppress
    let suppressedByInteraction: Bool
    let interactionNote: String?
    let rationaleText: String?
    let foodSources: [String]
}

struct SupplementPlan: Codable, Sendable {
    let enabled: Bool
    let withheldReason: String?
    let items: [PlanItem]
}

// MARK: - Intake taxonomy (mirrors packages/core/src/taxonomy.ts)

enum MedicationClass: String, CaseIterable, Identifiable, Codable {
    case anticoagulant, antiplatelet, aceInhibitor = "ace_inhibitor", arb
    case potassiumSparingDiuretic = "potassium_sparing_diuretic"
    case loopDiuretic = "loop_diuretic", thiazideDiuretic = "thiazide_diuretic"
    case thyroidHormone = "thyroid_hormone", levothyroxine, statin, metformin, ppi
    case diabetesOther = "diabetes_other", immunosuppressant, chemotherapy
    case lithium, digoxin, ironSupplement = "iron_supplement", other
    var id: String { rawValue }
    var display: String {
        switch self {
        case .aceInhibitor: return "ACE inhibitor"
        case .arb: return "ARB"
        case .potassiumSparingDiuretic: return "Potassium-sparing diuretic"
        case .loopDiuretic: return "Loop diuretic"
        case .thiazideDiuretic: return "Thiazide diuretic"
        case .thyroidHormone: return "Thyroid hormone"
        case .ppi: return "Proton-pump inhibitor"
        case .diabetesOther: return "Other diabetes medication"
        case .ironSupplement: return "Iron supplement"
        default: return rawValue.capitalized
        }
    }
}

enum HealthCondition: String, CaseIterable, Identifiable, Codable {
    case ckd, kidneyDiseaseAdvanced = "kidney_disease_advanced"
    case thyroidDisorder = "thyroid_disorder", hyperthyroidism, hypothyroidism
    case hemochromatosis, liverDisease = "liver_disease", heartFailure = "heart_failure"
    case hypertension, diabetesType1 = "diabetes_type1", diabetesType2 = "diabetes_type2"
    case pregnancy, g6pdDeficiency = "g6pd_deficiency", other
    var id: String { rawValue }
    var display: String {
        switch self {
        case .ckd: return "Chronic kidney disease"
        case .kidneyDiseaseAdvanced: return "Advanced kidney disease"
        case .thyroidDisorder: return "Thyroid disorder"
        case .hemochromatosis: return "Hemochromatosis (iron overload)"
        case .liverDisease: return "Liver disease"
        case .heartFailure: return "Heart failure"
        case .diabetesType1: return "Type 1 diabetes"
        case .diabetesType2: return "Type 2 diabetes"
        case .g6pdDeficiency: return "G6PD deficiency"
        default: return rawValue.capitalized
        }
    }
}
