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
        lengthMM >= widthMM
            ? self
            : BoxDimensions(lengthMM: widthMM, widthMM: lengthMM, heightMM: heightMM)
    }

    func formatted(unit: LengthUnitPreference = .automatic) -> String {
        switch unit.resolved {
        case .metric:
            String(format: "%.1f × %.1f × %.1f cm", lengthMM / 10, widthMM / 10, heightMM / 10)
        case .imperial:
            String(format: "%.1f × %.1f × %.1f in", lengthMM / 25.4, widthMM / 25.4, heightMM / 25.4)
        case .automatic:
            formatted(unit: .metric)
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

struct PaperSpec: Codable, Hashable, Sendable {
    var widthMM: Double
    var heightMM: Double

    var area: Double { widthMM * heightMM }
    var isValid: Bool {
        widthMM.isFinite && heightMM.isFinite
            && widthMM >= 10 && heightMM >= 10
            && widthMM <= 5_000 && heightMM <= 5_000
    }

    func formatted(unit: LengthUnitPreference = .automatic) -> String {
        switch unit.resolved {
        case .metric:
            String(format: "%.1f × %.1f cm", widthMM / 10, heightMM / 10)
        case .imperial:
            String(format: "%.1f × %.1f in", widthMM / 25.4, heightMM / 25.4)
        case .automatic:
            formatted(unit: .metric)
        }
    }
}

enum PaperStrategy: String, Codable, CaseIterable, Sendable {
    case easyWrap
    case justFit
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

enum PlannerRoute: String, Sendable {
    case input
    case results
}

enum PlannerSheet: String, Identifiable, Sendable {
    case customPaper

    var id: String { rawValue }
}
