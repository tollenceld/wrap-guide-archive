import Foundation

struct BoxDimensions: Codable, Hashable, Sendable {
    var lengthMM: Double
    var widthMM: Double
    var heightMM: Double

    static let phoneBox = BoxDimensions(lengthMM: 214, widthMM: 138, heightMM: 62)

    var isValid: Bool {
        [lengthMM, widthMM, heightMM].allSatisfy { $0.isFinite && $0 >= 5 && $0 <= 2_000 }
    }

    var sorted: BoxDimensions {
        lengthMM >= widthMM ? self : BoxDimensions(lengthMM: widthMM, widthMM: lengthMM, heightMM: heightMM)
    }

    func formatted(unit: LengthUnitPreference = .automatic) -> String {
        let resolved = unit.resolved
        switch resolved {
        case .metric:
            return String(format: "%.1f × %.1f × %.1f cm", lengthMM / 10, widthMM / 10, heightMM / 10)
        case .imperial:
            return String(format: "%.1f × %.1f × %.1f in", lengthMM / 25.4, widthMM / 25.4, heightMM / 25.4)
        case .automatic:
            return formatted(unit: .metric)
        }
    }
}

enum LengthUnitPreference: String, Codable, CaseIterable, Identifiable, Sendable {
    case automatic
    case metric
    case imperial

    var id: String { rawValue }

    var resolved: LengthUnitPreference {
        guard self == .automatic else { return self }
        return Locale.current.measurementSystem == .us ? .imperial : .metric
    }
}

struct BoxPose: Codable, Hashable, Sendable {
    var x: Float
    var y: Float
    var z: Float
    var yaw: Float

    static let identity = BoxPose(x: 0, y: 0, z: 0, yaw: 0)
}

enum MeasurementSource: String, Codable, Sendable {
    case automatic
    case assisted
    case manual
    case simulated
}

struct MeasurementResult: Codable, Hashable, Sendable {
    var dimensions: BoxDimensions
    var boxPose: BoxPose
    var confidence: Double
    var source: MeasurementSource
    var diagnostics: [String]
}

struct PaperSpec: Codable, Hashable, Sendable {
    var widthMM: Double
    var heightMM: Double

    var area: Double { widthMM * heightMM }
    var isValid: Bool { widthMM >= 10 && heightMM >= 10 && widthMM <= 5_000 && heightMM <= 5_000 }

    func formatted(unit: LengthUnitPreference = .automatic) -> String {
        switch unit.resolved {
        case .metric:
            return String(format: "%.1f × %.1f cm", widthMM / 10, heightMM / 10)
        case .imperial:
            return String(format: "%.1f × %.1f in", widthMM / 25.4, heightMM / 25.4)
        case .automatic:
            return formatted(unit: .metric)
        }
    }
}

enum PaperStrategy: String, Codable, CaseIterable, Sendable {
    case justFit
    case easyWrap
    case custom
}

enum BoxOrientation: String, Codable, Sendable {
    case longAxis
    case shortAxis
}

enum PaperDifficulty: String, Codable, Sendable {
    case roomy
    case comfortable
    case precise
    case insufficient
}

struct PaperMargins: Codable, Hashable, Sendable {
    var seamOverlapMM: Double
    var endAllowanceMM: Double
}

struct PaperPlan: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var strategy: PaperStrategy
    var sheetSize: PaperSpec
    var cutSize: PaperSpec
    var orientation: BoxOrientation
    var rotationDegrees: Double
    var margins: PaperMargins
    var wasteRatio: Double
    var difficulty: PaperDifficulty
    var recommendsCutting: Bool

    var isFeasible: Bool { difficulty != .insufficient }
}

enum GuidanceMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case handheld
    case tabletop

    var id: String { rawValue }
}

enum FlowStage: String, Codable, Sendable {
    case home
    case scan
    case manualMeasurement
    case confirmDimensions
    case paperPlans
    case preparation
    case guidance
    case completed
}

struct WrapSession: Codable, Hashable, Sendable {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var stage: FlowStage
    var dimensions: BoxDimensions?
    var measurement: MeasurementResult?
    var selectedPaperPlan: PaperPlan?
    var actualPaper: PaperSpec?
    var guidanceMode: GuidanceMode
    var currentStep: Int

    static func new() -> WrapSession {
        WrapSession(
            id: UUID(),
            createdAt: .now,
            updatedAt: .now,
            stage: .home,
            dimensions: nil,
            measurement: nil,
            selectedPaperPlan: nil,
            actualPaper: nil,
            guidanceMode: .handheld,
            currentStep: 0
        )
    }
}

