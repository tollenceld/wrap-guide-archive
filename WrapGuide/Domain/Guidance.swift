import Foundation

struct NormalizedPoint: Codable, Hashable, Sendable {
    var x: Float
    var y: Float

    func interpolated(to other: NormalizedPoint, progress: Float) -> NormalizedPoint {
        NormalizedPoint(
            x: x + (other.x - x) * progress,
            y: y + (other.y - y) * progress
        )
    }
}

enum WrapPhase: String, Codable, CaseIterable, Identifiable, Sendable {
    case placement
    case bodyWrap
    case mainSeam
    case firstEnd
    case secondEnd
    case finish

    var id: String { rawValue }

    var titleKey: String {
        "phase.\(rawValue)"
    }
}

enum GuidanceViewpoint: String, Codable, Sendable {
    case overhead
    case endFace
    case presentation
}

enum PaperLayerRole: String, Codable, Sendable {
    case context
    case active
    case target
    case completed
}

enum OverlayPrimitive: Codable, Hashable, Sendable {
    case boxOutline
    case ghostBox
    case paperSurface(points: [NormalizedPoint], role: PaperLayerRole)
    case paperFlap(start: [NormalizedPoint], end: [NormalizedPoint])
    case targetRegion(points: [NormalizedPoint])
    case foldLine(from: NormalizedPoint, to: NormalizedPoint)
    case alignmentLine(from: NormalizedPoint, to: NormalizedPoint)
    case motionPath(points: [NormalizedPoint])
    case tape(at: NormalizedPoint, angleDegrees: Float)
}

struct GuidanceStep: Codable, Hashable, Sendable, Identifiable {
    var id: Int
    var phase: WrapPhase
    var titleKey: String
    var instructionKey: String
    var viewpoint: GuidanceViewpoint
    var requiresRelock: Bool
    var targetHoldSeconds: Double
    var primitives: [OverlayPrimitive]

    var hasActiveAction: Bool {
        primitives.contains { primitive in
            switch primitive {
            case .paperFlap, .motionPath, .tape, .ghostBox:
                true
            default:
                false
            }
        }
    }

    var hasTarget: Bool {
        primitives.contains { primitive in
            switch primitive {
            case .targetRegion, .tape, .alignmentLine, .ghostBox:
                true
            default:
                false
            }
        }
    }
}

protocol WrapMethod: Sendable {
    var identifier: String { get }
    var steps: [GuidanceStep] { get }
}

struct StandardBoxWrapMethod: WrapMethod {
    let identifier = "standard-box-wrap-v2"

    let steps: [GuidanceStep] = [
        GuidanceStep(
            id: 1,
            phase: .placement,
            titleKey: "step.1.title",
            instructionKey: "step.1.instruction",
            viewpoint: .overhead,
            requiresRelock: true,
            targetHoldSeconds: 0.55,
            primitives: [
                .paperSurface(points: rect(0.07, 0.16, 0.93, 0.88), role: .context),
                .ghostBox,
                .targetRegion(points: rect(0.29, 0.31, 0.71, 0.69)),
                .motionPath(points: [point(0.50, 0.10), point(0.62, 0.24), point(0.50, 0.42)]),
                .boxOutline
            ]
        ),
        foldStep(
            id: 2,
            phase: .bodyWrap,
            title: "step.2.title",
            instruction: "step.2.instruction",
            start: rect(0.18, 0.70, 0.82, 0.96),
            end: rect(0.22, 0.47, 0.78, 0.70),
            crease: (0.18, 0.70, 0.82, 0.70),
            path: [(0.50, 0.90), (0.62, 0.72), (0.50, 0.55)]
        ),
        foldStep(
            id: 3,
            phase: .bodyWrap,
            title: "step.3.title",
            instruction: "step.3.instruction",
            start: rect(0.18, 0.04, 0.82, 0.30),
            end: rect(0.22, 0.30, 0.78, 0.54),
            crease: (0.18, 0.30, 0.82, 0.30),
            path: [(0.50, 0.10), (0.38, 0.29), (0.50, 0.46)]
        ),
        GuidanceStep(
            id: 4,
            phase: .mainSeam,
            titleKey: "step.4.title",
            instructionKey: "step.4.instruction",
            viewpoint: .overhead,
            requiresRelock: false,
            targetHoldSeconds: 0.70,
            primitives: [
                .paperSurface(points: rect(0.22, 0.30, 0.78, 0.70), role: .completed),
                .alignmentLine(from: point(0.31, 0.50), to: point(0.69, 0.50)),
                .motionPath(points: [point(0.50, 0.30), point(0.61, 0.40), point(0.50, 0.50)]),
                .tape(at: point(0.50, 0.50), angleDegrees: 0),
                .boxOutline
            ]
        ),
        endTopStep(id: 5, phase: .firstEnd, title: "step.5.title", instruction: "step.5.instruction", relock: true),
        endCornerStep(id: 6, phase: .firstEnd, title: "step.6.title", instruction: "step.6.instruction"),
        endSealStep(id: 7, phase: .firstEnd, title: "step.7.title", instruction: "step.7.instruction"),
        GuidanceStep(
            id: 8,
            phase: .secondEnd,
            titleKey: "step.8.title",
            instructionKey: "step.8.instruction",
            viewpoint: .endFace,
            requiresRelock: true,
            targetHoldSeconds: 0.55,
            primitives: [
                .ghostBox,
                .targetRegion(points: rect(0.28, 0.27, 0.72, 0.73)),
                .motionPath(points: [point(0.24, 0.63), point(0.50, 0.78), point(0.76, 0.63)]),
                .boxOutline
            ]
        ),
        endTopStep(id: 9, phase: .secondEnd, title: "step.9.title", instruction: "step.9.instruction", relock: false),
        endCornerStep(id: 10, phase: .secondEnd, title: "step.10.title", instruction: "step.10.instruction"),
        endSealStep(id: 11, phase: .secondEnd, title: "step.11.title", instruction: "step.11.instruction"),
        GuidanceStep(
            id: 12,
            phase: .finish,
            titleKey: "step.12.title",
            instructionKey: "step.12.instruction",
            viewpoint: .presentation,
            requiresRelock: false,
            targetHoldSeconds: 0.75,
            primitives: [
                .paperSurface(points: rect(0.25, 0.27, 0.75, 0.73), role: .completed),
                .alignmentLine(from: point(0.30, 0.68), to: point(0.70, 0.68)),
                .motionPath(points: [point(0.27, 0.62), point(0.50, 0.78), point(0.73, 0.48)]),
                .targetRegion(points: rect(0.27, 0.24, 0.73, 0.70)),
                .boxOutline
            ]
        )
    ]

    private static func point(_ x: Float, _ y: Float) -> NormalizedPoint {
        NormalizedPoint(x: x, y: y)
    }

    private static func rect(_ x0: Float, _ y0: Float, _ x1: Float, _ y1: Float) -> [NormalizedPoint] {
        [point(x0, y0), point(x1, y0), point(x1, y1), point(x0, y1)]
    }

    private static func foldStep(
        id: Int,
        phase: WrapPhase,
        title: String,
        instruction: String,
        start: [NormalizedPoint],
        end: [NormalizedPoint],
        crease: (Float, Float, Float, Float),
        path: [(Float, Float)]
    ) -> GuidanceStep {
        GuidanceStep(
            id: id,
            phase: phase,
            titleKey: title,
            instructionKey: instruction,
            viewpoint: .overhead,
            requiresRelock: false,
            targetHoldSeconds: 0.55,
            primitives: [
                .targetRegion(points: end),
                .paperFlap(start: start, end: end),
                .foldLine(from: point(crease.0, crease.1), to: point(crease.2, crease.3)),
                .motionPath(points: path.map { point($0.0, $0.1) }),
                .boxOutline
            ]
        )
    }

    private static func endTopStep(
        id: Int,
        phase: WrapPhase,
        title: String,
        instruction: String,
        relock: Bool
    ) -> GuidanceStep {
        foldStep(
            id: id,
            phase: phase,
            title: title,
            instruction: instruction,
            start: [point(0.27, 0.08), point(0.73, 0.08), point(0.78, 0.34), point(0.22, 0.34)],
            end: [point(0.28, 0.31), point(0.72, 0.31), point(0.70, 0.54), point(0.30, 0.54)],
            crease: (0.25, 0.34, 0.75, 0.34),
            path: [(0.50, 0.12), (0.63, 0.28), (0.50, 0.46)]
        ).withRelock(relock)
    }

    private static func endCornerStep(id: Int, phase: WrapPhase, title: String, instruction: String) -> GuidanceStep {
        GuidanceStep(
            id: id,
            phase: phase,
            titleKey: title,
            instructionKey: instruction,
            viewpoint: .endFace,
            requiresRelock: false,
            targetHoldSeconds: 0.60,
            primitives: [
                .targetRegion(points: [point(0.28, 0.36), point(0.45, 0.49), point(0.28, 0.64)]),
                .targetRegion(points: [point(0.72, 0.36), point(0.55, 0.49), point(0.72, 0.64)]),
                .paperFlap(
                    start: [point(0.04, 0.28), point(0.28, 0.36), point(0.45, 0.49), point(0.12, 0.69)],
                    end: [point(0.28, 0.36), point(0.45, 0.49), point(0.28, 0.64), point(0.22, 0.50)]
                ),
                .paperFlap(
                    start: [point(0.96, 0.28), point(0.72, 0.36), point(0.55, 0.49), point(0.88, 0.69)],
                    end: [point(0.72, 0.36), point(0.55, 0.49), point(0.72, 0.64), point(0.78, 0.50)]
                ),
                .foldLine(from: point(0.27, 0.35), to: point(0.45, 0.52)),
                .foldLine(from: point(0.73, 0.35), to: point(0.55, 0.52)),
                .motionPath(points: [point(0.10, 0.50), point(0.25, 0.50), point(0.40, 0.50)]),
                .motionPath(points: [point(0.90, 0.50), point(0.75, 0.50), point(0.60, 0.50)]),
                .boxOutline
            ]
        )
    }

    private static func endSealStep(id: Int, phase: WrapPhase, title: String, instruction: String) -> GuidanceStep {
        GuidanceStep(
            id: id,
            phase: phase,
            titleKey: title,
            instructionKey: instruction,
            viewpoint: .endFace,
            requiresRelock: false,
            targetHoldSeconds: 0.70,
            primitives: [
                .targetRegion(points: rect(0.28, 0.48, 0.72, 0.70)),
                .paperFlap(
                    start: [point(0.22, 0.92), point(0.78, 0.92), point(0.72, 0.68), point(0.28, 0.68)],
                    end: rect(0.28, 0.48, 0.72, 0.70)
                ),
                .foldLine(from: point(0.25, 0.69), to: point(0.75, 0.69)),
                .motionPath(points: [point(0.50, 0.89), point(0.63, 0.71), point(0.50, 0.56)]),
                .tape(at: point(0.50, 0.57), angleDegrees: 0),
                .boxOutline
            ]
        )
    }
}

private extension GuidanceStep {
    func withRelock(_ relock: Bool) -> GuidanceStep {
        var copy = self
        copy.requiresRelock = relock
        return copy
    }
}
