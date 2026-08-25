import ARKit
import RealityKit
import SwiftUI
import Vision

enum ScanPhase: String, Equatable, Sendable {
    case findingSurface
    case candidate
    case buildingEdges
    case stabilizing
    case locked
    case limited
}

enum ScanRecoveryReason: String, Equatable, Sendable {
    case lowLight
    case excessiveMotion
    case occluded
    case heightUnavailable
}

struct ScanVisualizationState: Equatable, Sendable {
    var phase: ScanPhase
    var candidate: [NormalizedPoint]
    var edgeProgress: Double
    var dimensions: BoxDimensions?
    var confidence: Double
    var recovery: ScanRecoveryReason?

    static let searching = ScanVisualizationState(
        phase: .findingSurface,
        candidate: [],
        edgeProgress: 0,
        dimensions: nil,
        confidence: 0,
        recovery: nil
    )

    var localizedKey: LocalizedStringKey {
        if let recovery {
            return switch recovery {
            case .lowLight: "scan.status.light"
            case .excessiveMotion: "scan.status.slow"
            case .occluded: "scan.status.occluded"
            case .heightUnavailable: "scan.status.height"
            }
        }
        return switch phase {
        case .findingSurface: "scan.status.surface"
        case .candidate: "scan.status.box"
        case .buildingEdges: "scan.status.edges"
        case .stabilizing: "scan.status.stabilizing"
        case .locked: "scan.status.stable"
        case .limited: "scan.status.recover"
        }
    }

    var icon: String {
        if let recovery {
            return switch recovery {
            case .lowLight: "sun.min.fill"
            case .excessiveMotion: "iphone.gen3.radiowaves.left.and.right"
            case .occluded: "eye.slash.fill"
            case .heightUnavailable: "arrow.up.and.down"
            }
        }
        return switch phase {
        case .findingSurface: "viewfinder"
        case .candidate: "shippingbox"
        case .buildingEdges: "square.dashed.inset.filled"
        case .stabilizing: "scope"
        case .locked: "checkmark.seal.fill"
        case .limited: "exclamationmark.triangle.fill"
        }
    }
}

@MainActor
struct ARScannerView: View {
    @Binding var state: ScanVisualizationState
    let onMeasurement: @MainActor @Sendable (MeasurementResult) -> Void

    var body: some View {
        #if targetEnvironment(simulator)
        SimulatorScannerView(state: $state, onMeasurement: onMeasurement)
        #else
        DeviceARScannerRepresentable(state: $state, onMeasurement: onMeasurement)
        #endif
    }
}

#if targetEnvironment(simulator)
private struct SimulatorScannerView: View {
    @Binding var state: ScanVisualizationState
    let onMeasurement: @MainActor @Sendable (MeasurementResult) -> Void
    @State private var hasCompleted = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.14, blue: 0.15), Color(red: 0.025, green: 0.035, blue: 0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color.white.opacity(0.08), .clear],
                center: .center,
                startRadius: 40,
                endRadius: 340
            )
        }
        .overlay(alignment: .top) {
            Text("scan.simulator")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(AppTheme.amber, in: Capsule())
                .foregroundStyle(.black)
                .padding(.top, 116)
        }
        .task {
            guard !hasCompleted else { return }
            let quad = [
                NormalizedPoint(x: 0.20, y: 0.34),
                NormalizedPoint(x: 0.78, y: 0.31),
                NormalizedPoint(x: 0.84, y: 0.65),
                NormalizedPoint(x: 0.16, y: 0.68)
            ]
            state = .searching
            try? await Task.sleep(for: .milliseconds(500))
            state.phase = .candidate
            state.candidate = quad
            state.edgeProgress = 0.18
            try? await Task.sleep(for: .milliseconds(520))
            state.phase = .buildingEdges
            state.edgeProgress = 0.64
            state.dimensions = .phoneBox
            state.confidence = 0.72
            try? await Task.sleep(for: .milliseconds(600))
            state.phase = .stabilizing
            state.edgeProgress = 0.94
            state.confidence = 0.88
            try? await Task.sleep(for: .milliseconds(520))
            state.phase = .locked
            state.edgeProgress = 1
            state.confidence = 0.92
            hasCompleted = true
            try? await Task.sleep(for: .milliseconds(420))
            onMeasurement(MeasurementResult(
                dimensions: .phoneBox,
                boxPose: .identity,
                confidence: 0.92,
                source: .simulated,
                diagnostics: ["simulator-fixture"]
            ))
        }
    }
}
#else
private struct DeviceARScannerRepresentable: UIViewRepresentable {
    @Binding var state: ScanVisualizationState
    let onMeasurement: @MainActor @Sendable (MeasurementResult) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(state: $state, onMeasurement: onMeasurement)
    }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        context.coordinator.arView = view
        view.session.delegate = context.coordinator

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = []
        }
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
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    final class Coordinator: NSObject, ARSessionDelegate, @unchecked Sendable {
        weak var arView: ARView?
        private var state: Binding<ScanVisualizationState>
        private let onMeasurement: @MainActor (MeasurementResult) -> Void
        private let visionQueue = DispatchQueue(label: "com.wrapguide.vision", qos: .userInitiated)
        private var lastVisionTime: TimeInterval = 0
        private var isProcessing = false
        private var planeHeights: [Float] = []
        private var stableSamples: [BoxDimensions] = []
        private var delivered = false

        init(state: Binding<ScanVisualizationState>, onMeasurement: @escaping @MainActor (MeasurementResult) -> Void) {
            self.state = state
            self.onMeasurement = onMeasurement
        }

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            updatePlanes(from: anchors)
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            updatePlanes(from: anchors)
        }

        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            guard !delivered else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch camera.trackingState {
                case .normal:
                    if state.wrappedValue.phase == .limited { state.wrappedValue = .searching }
                case .limited(let reason):
                    if reason == .excessiveMotion {
                        state.wrappedValue.phase = .limited
                        state.wrappedValue.recovery = .excessiveMotion
                    }
                case .notAvailable:
                    state.wrappedValue = .searching
                }
            }
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard !delivered, !isProcessing, frame.timestamp - lastVisionTime > 0.28 else { return }
            if let intensity = frame.lightEstimate?.ambientIntensity, intensity < 160 {
                Task { @MainActor [weak self] in
                    self?.state.wrappedValue.phase = .limited
                    self?.state.wrappedValue.recovery = .lowLight
                }
                return
            }
            guard case .normal = frame.camera.trackingState else { return }

            isProcessing = true
            lastVisionTime = frame.timestamp
            let pixelBuffer = SendablePixelBuffer(value: frame.capturedImage)

            visionQueue.async { [weak self] in
                guard let self else { return }
                let request = VNDetectRectanglesRequest()
                request.maximumObservations = 3
                request.minimumConfidence = 0.65
                request.minimumSize = 0.12
                request.quadratureTolerance = 22
                do {
                    try VNImageRequestHandler(cvPixelBuffer: pixelBuffer.value, orientation: .right).perform([request])
                    let best = request.results?.max(by: { $0.boundingBox.area < $1.boundingBox.area })
                    Task { @MainActor [weak self] in self?.process(best) }
                } catch {
                    Task { @MainActor [weak self] in self?.isProcessing = false }
                }
            }
        }

        @MainActor
        private func process(_ observation: VNRectangleObservation?) {
            defer { isProcessing = false }
            guard let observation, let arView else {
                state.wrappedValue.phase = .findingSurface
                state.wrappedValue.recovery = .occluded
                return
            }

            let normalized = [observation.topLeft, observation.topRight, observation.bottomRight, observation.bottomLeft].map {
                NormalizedPoint(x: Float($0.x), y: Float(1 - $0.y))
            }
            state.wrappedValue.candidate = normalized
            state.wrappedValue.recovery = nil
            state.wrappedValue.phase = stableSamples.isEmpty ? .candidate : .buildingEdges
            state.wrappedValue.edgeProgress = min(0.92, 0.18 + Double(stableSamples.count) / 9)

            let points = normalized.map {
                CGPoint(x: CGFloat($0.x) * arView.bounds.width, y: CGFloat($0.y) * arView.bounds.height)
            }
            let worldPoints = points.compactMap {
                arView.raycast(from: $0, allowing: .estimatedPlane, alignment: .horizontal).first?.worldTransform.translation
            }
            guard worldPoints.count == 4 else {
                state.wrappedValue.recovery = .heightUnavailable
                return
            }

            let a = simd_distance(worldPoints[0], worldPoints[1])
            let b = simd_distance(worldPoints[1], worldPoints[2])
            let c = simd_distance(worldPoints[2], worldPoints[3])
            let d = simd_distance(worldPoints[3], worldPoints[0])
            let side1 = Double((a + c) / 2 * 1_000)
            let side2 = Double((b + d) / 2 * 1_000)
            let topY = worldPoints.map(\.y).reduce(0, +) / 4
            guard let tableY = planeHeights.filter({ $0 < topY - 0.005 }).max() else {
                state.wrappedValue.phase = .stabilizing
                state.wrappedValue.recovery = .heightUnavailable
                return
            }
            let height = Double((topY - tableY) * 1_000)
            let candidate = BoxDimensions(lengthMM: max(side1, side2), widthMM: min(side1, side2), heightMM: height)
            guard candidate.isValid, candidate.heightMM < min(candidate.lengthMM, candidate.widthMM) * 1.5 else { return }

            state.wrappedValue.dimensions = candidate.sorted
            stableSamples.append(candidate)
            if stableSamples.count > 12 { stableSamples.removeFirst() }
            guard stableSamples.count >= 8 else {
                state.wrappedValue.phase = .stabilizing
                state.wrappedValue.confidence = Double(stableSamples.count) / 10
                return
            }

            let median = BoxDimensions(
                lengthMM: stableSamples.map(\.lengthMM).median,
                widthMM: stableSamples.map(\.widthMM).median,
                heightMM: stableSamples.map(\.heightMM).median
            )
            let maxDeviation = stableSamples.map {
                max(abs($0.lengthMM - median.lengthMM), abs($0.widthMM - median.widthMM), abs($0.heightMM - median.heightMM))
            }.max() ?? .infinity
            guard maxDeviation <= max(5, median.lengthMM * 0.03) else { return }

            delivered = true
            state.wrappedValue.phase = .locked
            state.wrappedValue.edgeProgress = 1
            state.wrappedValue.dimensions = median
            state.wrappedValue.confidence = 0.86
            state.wrappedValue.recovery = nil
            let pose = worldPoints.reduce(SIMD3<Float>.zero, +) / 4
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(420))
                onMeasurement(MeasurementResult(
                    dimensions: median,
                    boxPose: BoxPose(x: pose.x, y: pose.y, z: pose.z, yaw: 0),
                    confidence: 0.86,
                    source: .automatic,
                    diagnostics: ["vision-rectangle", "estimated-plane", "multi-frame-median"]
                ))
            }
        }

        private func updatePlanes(from anchors: [ARAnchor]) {
            let updates = anchors.compactMap { ($0 as? ARPlaneAnchor)?.transform.translation.y }
            planeHeights.append(contentsOf: updates)
            planeHeights = Array(planeHeights.suffix(24))
        }
    }
}

private struct SendablePixelBuffer: @unchecked Sendable {
    let value: CVPixelBuffer
}

private extension CGRect {
    var area: CGFloat { width * height }
}

private extension simd_float4x4 {
    var translation: SIMD3<Float> { SIMD3(columns.3.x, columns.3.y, columns.3.z) }
}

private extension Array where Element == Double {
    var median: Double {
        let sorted = sorted()
        guard !sorted.isEmpty else { return 0 }
        if sorted.count.isMultiple(of: 2) {
            return (sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2
        }
        return sorted[sorted.count / 2]
    }
}
#endif
