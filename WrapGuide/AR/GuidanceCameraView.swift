import ARKit
import RealityKit
import SwiftUI

@MainActor
struct GuidanceCameraView: View {
    let step: GuidanceStep
    let dimensions: BoxDimensions
    let relockToken: UUID

    var body: some View {
        #if targetEnvironment(simulator)
        GuidanceDiagramView(step: step, dimensions: dimensions)
        #else
        DeviceGuidanceRepresentable(step: step, dimensions: dimensions, relockToken: relockToken)
        #endif
    }
}

#if !targetEnvironment(simulator)
private struct DeviceGuidanceRepresentable: UIViewRepresentable {
    let step: GuidanceStep
    let dimensions: BoxDimensions
    let relockToken: UUID

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        context.coordinator.arView = view

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        view.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        let coaching = ARCoachingOverlayView()
        coaching.session = view.session
        coaching.goal = .horizontalPlane
        coaching.activatesAutomatically = true
        coaching.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(coaching)
        NSLayoutConstraint.activate([
            coaching.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            coaching.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            coaching.topAnchor.constraint(equalTo: view.topAnchor),
            coaching.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        context.coordinator.render(step: step, dimensions: dimensions, relock: true)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        let shouldRelock = context.coordinator.lastRelockToken != relockToken
        context.coordinator.lastRelockToken = relockToken
        context.coordinator.render(step: step, dimensions: dimensions, relock: shouldRelock)
    }

    @MainActor
    final class Coordinator {
        weak var arView: ARView?
        var lastRelockToken: UUID?
        private var anchor: AnchorEntity?
        private var contentRoot: Entity?
        private var lastStepID: Int?

        func render(step: GuidanceStep, dimensions: BoxDimensions, relock: Bool) {
            guard let arView else { return }
            if relock || anchor == nil {
                if let anchor { arView.scene.removeAnchor(anchor) }
                let placement: SIMD3<Float>
                if let hit = arView.raycast(from: arView.bounds.center, allowing: .estimatedPlane, alignment: .horizontal).first {
                    placement = hit.worldTransform.translation + SIMD3(0, 0.004, 0)
                } else {
                    placement = SIMD3(0, -0.22, -0.65)
                }
                let newAnchor = AnchorEntity(world: placement)
                let newRoot = Entity()
                newAnchor.addChild(newRoot)
                arView.scene.addAnchor(newAnchor)
                anchor = newAnchor
                contentRoot = newRoot
                lastStepID = nil
            }
            guard lastStepID != step.id, let anchor, let contentRoot else { return }
            contentRoot.children.removeAll()
            lastStepID = step.id
            GuidanceRealityRenderer.render(step: step, dimensions: dimensions, into: contentRoot, relativeTo: anchor)
        }
    }
}

@MainActor
private enum GuidanceRealityRenderer {
    static func render(step: GuidanceStep, dimensions: BoxDimensions, into root: Entity, relativeTo anchor: AnchorEntity) {
        let width = Float(dimensions.widthMM / 1_000)
        let length = Float(dimensions.lengthMM / 1_000)
        let height = Float(dimensions.heightMM / 1_000)

        addBoxOutline(width: width, length: length, height: height, color: .white.withAlphaComponent(0.88), to: root)

        for primitive in step.primitives {
            switch primitive {
            case .boxOutline:
                break
            case .ghostBox:
                addBoxOutline(width: width * 1.04, length: length * 1.04, height: height, color: UIColor(AppTheme.cyan).withAlphaComponent(0.58), to: root)
            case let .paperSurface(points, role):
                addRegion(points: points, width: width, length: length, height: height, color: color(for: role), to: root)
            case let .paperFlap(start, end):
                addAnimatedFlap(start: start, end: end, width: width, length: length, height: height, to: root, relativeTo: anchor)
            case let .targetRegion(points):
                addRegion(points: points, width: width, length: length, height: height, color: UIColor(AppTheme.cyan).withAlphaComponent(0.16), to: root)
            case let .foldLine(from, to):
                addLine(from: local(from, width: width, length: length, height: height), to: local(to, width: width, length: length, height: height), color: UIColor(AppTheme.cyan), dashed: true, to: root)
            case let .alignmentLine(from, to):
                addLine(from: local(from, width: width, length: length, height: height), to: local(to, width: width, length: length, height: height), color: .white.withAlphaComponent(0.82), dashed: false, to: root)
            case let .motionPath(points):
                for pair in zip(points, points.dropFirst()) {
                    addLine(
                        from: local(pair.0, width: width, length: length, height: height),
                        to: local(pair.1, width: width, length: length, height: height),
                        color: UIColor(AppTheme.blue),
                        dashed: false,
                        to: root
                    )
                }
                if let target = points.last {
                    let marker = ModelEntity(mesh: .generateSphere(radius: 0.009), materials: [SimpleMaterial(color: UIColor(AppTheme.blue), isMetallic: false)])
                    marker.position = local(target, width: width, length: length, height: height)
                    root.addChild(marker)
                }
            case let .tape(at, angleDegrees):
                let marker = ModelEntity(mesh: .generateBox(size: SIMD3(0.035, 0.003, 0.012)), materials: [SimpleMaterial(color: UIColor(AppTheme.amber), isMetallic: false)])
                marker.position = local(at, width: width, length: length, height: height)
                marker.orientation = simd_quatf(angle: angleDegrees * .pi / 180, axis: SIMD3(0, 1, 0))
                root.addChild(marker)
            }
        }
    }

    private static func local(_ point: NormalizedPoint, width: Float, length: Float, height: Float) -> SIMD3<Float> {
        SIMD3((point.x - 0.5) * width * 1.55, height + 0.006, (point.y - 0.5) * length * 1.55)
    }

    private static func color(for role: PaperLayerRole) -> UIColor {
        switch role {
        case .context: UIColor.white.withAlphaComponent(0.10)
        case .active: UIColor(AppTheme.blue).withAlphaComponent(0.34)
        case .target: UIColor(AppTheme.cyan).withAlphaComponent(0.18)
        case .completed: UIColor.white.withAlphaComponent(0.14)
        }
    }

    private static func addRegion(
        points: [NormalizedPoint],
        width: Float,
        length: Float,
        height: Float,
        color: UIColor,
        to root: Entity
    ) {
        guard let bounds = points.bounds else { return }
        let regionWidth = max(0.015, bounds.width * width * 1.55)
        let regionLength = max(0.015, bounds.height * length * 1.55)
        let region = ModelEntity(
            mesh: .generateBox(size: SIMD3(regionWidth, 0.0015, regionLength)),
            materials: [SimpleMaterial(color: color, isMetallic: false)]
        )
        region.position = local(bounds.center, width: width, length: length, height: height)
        root.addChild(region)
    }

    private static func addAnimatedFlap(
        start: [NormalizedPoint],
        end: [NormalizedPoint],
        width: Float,
        length: Float,
        height: Float,
        to root: Entity,
        relativeTo anchor: AnchorEntity
    ) {
        guard let startBounds = start.bounds, let endBounds = end.bounds else { return }
        let startWidth = max(0.015, startBounds.width * width * 1.55)
        let startLength = max(0.015, startBounds.height * length * 1.55)
        let flap = ModelEntity(
            mesh: .generateBox(size: SIMD3(startWidth, 0.002, startLength)),
            materials: [SimpleMaterial(color: UIColor(AppTheme.blue).withAlphaComponent(0.38), isMetallic: false)]
        )
        flap.position = local(startBounds.center, width: width, length: length, height: height)
        root.addChild(flap)

        var target = flap.transform
        target.translation = local(endBounds.center, width: width, length: length, height: height)
        target.scale = SIMD3(
            max(0.25, endBounds.width / max(startBounds.width, 0.001)),
            1,
            max(0.25, endBounds.height / max(startBounds.height, 0.001))
        )
        flap.move(to: target, relativeTo: anchor, duration: 1.15, timingFunction: .easeInOut)
    }

    private static func addBoxOutline(width: Float, length: Float, height: Float, color: UIColor, to root: Entity) {
        let material = SimpleMaterial(color: color, isMetallic: false)
        let beam: Float = 0.003
        let xs: [Float] = [-width / 2, width / 2]
        let zs: [Float] = [-length / 2, length / 2]
        let ys: [Float] = [0, height]

        for y in ys {
            for z in zs {
                let entity = ModelEntity(mesh: .generateBox(size: SIMD3(width, beam, beam)), materials: [material])
                entity.position = SIMD3(0, y, z)
                root.addChild(entity)
            }
            for x in xs {
                let entity = ModelEntity(mesh: .generateBox(size: SIMD3(beam, beam, length)), materials: [material])
                entity.position = SIMD3(x, y, 0)
                root.addChild(entity)
            }
        }
        for x in xs {
            for z in zs {
                let entity = ModelEntity(mesh: .generateBox(size: SIMD3(beam, height, beam)), materials: [material])
                entity.position = SIMD3(x, height / 2, z)
                root.addChild(entity)
            }
        }
    }

    private static func addLine(from: SIMD3<Float>, to: SIMD3<Float>, color: UIColor, dashed: Bool, to root: Entity) {
        let delta = to - from
        let length = simd_length(delta)
        guard length > 0.001 else { return }
        let segmentCount = dashed ? max(1, Int(length / 0.018)) : 1
        for index in 0..<segmentCount where !dashed || index.isMultiple(of: 2) {
            let t0 = Float(index) / Float(segmentCount)
            let t1 = Float(index + 1) / Float(segmentCount)
            let start = from + delta * t0
            let end = from + delta * t1
            let segment = ModelEntity(mesh: .generateBox(size: SIMD3(0.004, 0.003, simd_distance(start, end))), materials: [SimpleMaterial(color: color, isMetallic: false)])
            segment.position = (start + end) / 2
            segment.look(at: end, from: segment.position, relativeTo: root)
            root.addChild(segment)
        }
    }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}

private extension simd_float4x4 {
    var translation: SIMD3<Float> { SIMD3(columns.3.x, columns.3.y, columns.3.z) }
}

private extension Array where Element == NormalizedPoint {
    var center: NormalizedPoint? {
        guard !isEmpty else { return nil }
        return NormalizedPoint(x: map(\.x).reduce(0, +) / Float(count), y: map(\.y).reduce(0, +) / Float(count))
    }

    var bounds: (center: NormalizedPoint, width: Float, height: Float)? {
        guard let first else { return nil }
        let minX = dropFirst().reduce(first.x) { Swift.min($0, $1.x) }
        let maxX = dropFirst().reduce(first.x) { Swift.max($0, $1.x) }
        let minY = dropFirst().reduce(first.y) { Swift.min($0, $1.y) }
        let maxY = dropFirst().reduce(first.y) { Swift.max($0, $1.y) }
        return (
            NormalizedPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2),
            maxX - minX,
            maxY - minY
        )
    }
}
#endif
