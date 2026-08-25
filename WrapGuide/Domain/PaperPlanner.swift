import Foundation

protocol PaperPlanning: Sendable {
    func recommend(for box: BoxDimensions) -> [PaperPlan]
    func evaluate(custom sheet: PaperSpec, for box: BoxDimensions) -> PaperPlan
}

struct PaperPlanner: PaperPlanning {
    static let justFitMargins = PaperMargins(seamOverlapMM: 15, endAllowanceMM: 5)
    static let easyWrapMargins = PaperMargins(seamOverlapMM: 30, endAllowanceMM: 15)

    func recommend(for box: BoxDimensions) -> [PaperPlan] {
        guard box.isValid else { return [] }
        return [
            recommendedPlan(for: box, strategy: .easyWrap, margins: Self.easyWrapMargins),
            recommendedPlan(for: box, strategy: .justFit, margins: Self.justFitMargins)
        ]
    }

    func evaluate(custom sheet: PaperSpec, for box: BoxDimensions) -> PaperPlan {
        guard box.isValid else { return insufficientPlan(sheet: sheet, required: sheet) }
        let minimum = layouts(for: box, margins: Self.justFitMargins).min { $0.cutSize.area < $1.cutSize.area }!
        guard sheet.isValid else { return insufficientPlan(sheet: sheet, required: minimum.cutSize) }

        if let fit = bestFit(sheet: sheet, box: box, margins: Self.easyWrapMargins) {
            return customPlan(
                sheet: sheet,
                fit: fit,
                margins: Self.easyWrapMargins,
                difficulty: oversized(sheet, comparedWith: fit.cutSize) ? .roomy : .comfortable
            )
        }

        if let fit = bestFit(sheet: sheet, box: box, margins: Self.justFitMargins) {
            return customPlan(sheet: sheet, fit: fit, margins: Self.justFitMargins, difficulty: .precise)
        }

        return insufficientPlan(sheet: sheet, required: minimum.cutSize)
    }

    private func recommendedPlan(for box: BoxDimensions, strategy: PaperStrategy, margins: PaperMargins) -> PaperPlan {
        let chosen = layouts(for: box, margins: margins).min { $0.cutSize.area < $1.cutSize.area }!
        return PaperPlan(
            id: strategy.rawValue,
            strategy: strategy,
            sheetSize: chosen.cutSize,
            cutSize: chosen.cutSize,
            orientation: chosen.orientation,
            rotationDegrees: 0,
            margins: margins,
            wasteRatio: 0,
            difficulty: strategy == .easyWrap ? .comfortable : .precise,
            recommendsCutting: false
        )
    }

    private func customPlan(sheet: PaperSpec, fit: Fit, margins: PaperMargins, difficulty: PaperDifficulty) -> PaperPlan {
        let waste = max(0, min(1, (sheet.area - fit.cutSize.area) / sheet.area))
        return PaperPlan(
            id: "custom-\(Int(sheet.widthMM))-\(Int(sheet.heightMM))",
            strategy: .custom,
            sheetSize: sheet,
            cutSize: fit.cutSize,
            orientation: fit.orientation,
            rotationDegrees: fit.rotationDegrees,
            margins: margins,
            wasteRatio: waste,
            difficulty: difficulty,
            recommendsCutting: oversized(sheet, comparedWith: fit.cutSize)
        )
    }

    private func insufficientPlan(sheet: PaperSpec, required: PaperSpec) -> PaperPlan {
        PaperPlan(
            id: "custom-insufficient",
            strategy: .custom,
            sheetSize: sheet,
            cutSize: required,
            orientation: .longAxis,
            rotationDegrees: 0,
            margins: Self.justFitMargins,
            wasteRatio: 0,
            difficulty: .insufficient,
            recommendsCutting: false
        )
    }

    private struct Fit: Sendable {
        var cutSize: PaperSpec
        var orientation: BoxOrientation
        var rotationDegrees: Double
    }

    private func bestFit(sheet: PaperSpec, box: BoxDimensions, margins: PaperMargins) -> Fit? {
        var fits: [Fit] = []
        for candidate in layouts(for: box, margins: margins) {
            if candidate.cutSize.widthMM <= sheet.widthMM && candidate.cutSize.heightMM <= sheet.heightMM {
                fits.append(candidate)
            }
            if candidate.cutSize.widthMM <= sheet.heightMM && candidate.cutSize.heightMM <= sheet.widthMM {
                fits.append(Fit(cutSize: candidate.cutSize, orientation: candidate.orientation, rotationDegrees: 90))
            }
        }
        return fits.min {
            if $0.rotationDegrees != $1.rotationDegrees { return $0.rotationDegrees < $1.rotationDegrees }
            return $0.cutSize.area < $1.cutSize.area
        }
    }

    private func layouts(for box: BoxDimensions, margins: PaperMargins) -> [Fit] {
        let box = box.sorted
        return [
            Fit(
                cutSize: cutSize(x: box.lengthMM, y: box.widthMM, h: box.heightMM, margins: margins),
                orientation: .longAxis,
                rotationDegrees: 0
            ),
            Fit(
                cutSize: cutSize(x: box.widthMM, y: box.lengthMM, h: box.heightMM, margins: margins),
                orientation: .shortAxis,
                rotationDegrees: 0
            )
        ]
    }

    private func cutSize(x: Double, y: Double, h: Double, margins: PaperMargins) -> PaperSpec {
        let around = 2 * (y + h) + margins.seamOverlapMM
        let along = x + 2 * h + 2 * margins.endAllowanceMM
        return PaperSpec(widthMM: roundedUp5(around), heightMM: roundedUp5(along))
    }

    private func roundedUp5(_ value: Double) -> Double {
        ceil(value / 5) * 5
    }

    private func oversized(_ sheet: PaperSpec, comparedWith cut: PaperSpec) -> Bool {
        let directExcess = max(sheet.widthMM - cut.widthMM, sheet.heightMM - cut.heightMM)
        let rotatedExcess = max(sheet.widthMM - cut.heightMM, sheet.heightMM - cut.widthMM)
        return sheet.area > cut.area * 1.35 || min(directExcess, rotatedExcess) > 50
    }
}
