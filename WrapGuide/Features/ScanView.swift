import SwiftUI

struct ScanView: View {
    let coordinator: AppCoordinator
    @State private var state = ScanVisualizationState.searching

    var body: some View {
        ZStack {
            ARScannerView(state: $state) { result in
                coordinator.acceptMeasurement(result)
            }
            .ignoresSafeArea()

            ScanSpatialOverlay(state: state)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    CameraScanCircleButton(icon: "xmark", label: "action.close") {
                        coordinator.goHome()
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("scan.title")
                            .font(.subheadline.weight(.bold))
                        Text("scan.live")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AppTheme.cyan)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 17)
                    .frame(height: 44)
                    .background(.ultraThinMaterial, in: Capsule())
                    .background(AppTheme.cameraPanel.opacity(0.68), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.10)))
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 14)

                Spacer()

                VStack(spacing: 12) {
                    HStack(spacing: 11) {
                        ZStack {
                            Circle()
                                .stroke(.white.opacity(0.14), lineWidth: 4)
                            Circle()
                                .trim(from: 0, to: max(0.05, state.edgeProgress))
                                .stroke(stateTint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(AppMotion.standard, value: state.edgeProgress)
                            Image(systemName: state.icon)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(stateTint)
                        }
                        .frame(width: 40, height: 40)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(state.localizedKey)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(scanHint)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.62))
                                .lineLimit(2)
                        }

                        Spacer(minLength: 0)
                    }

                    HStack {
                        if let dimensions = state.dimensions {
                            Text(dimensions.formatted())
                                .font(.subheadline.weight(.bold).monospacedDigit())
                                .foregroundStyle(.white)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        Spacer()
                        Button("scan.manual") {
                            coordinator.useManualMeasurement()
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.cyan)
                    }
                }
                .cameraSurface(padding: 16, radius: 24)
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: state.phase) { oldValue, newValue in
            if oldValue != .locked, newValue == .locked {
                AppHaptics.success()
            }
        }
    }

    private var stateTint: Color {
        if state.recovery != nil { return AppTheme.amber }
        return state.phase == .locked ? AppTheme.cyan : .white
    }

    private var scanHint: LocalizedStringKey {
        switch state.phase {
        case .findingSurface: "scan.hint.surface"
        case .candidate, .buildingEdges: "scan.hint.edges"
        case .stabilizing: "scan.hint.stabilize"
        case .locked: "scan.hint.locked"
        case .limited: "scan.hint.recover"
        }
    }
}

private struct CameraScanCircleButton: View {
    let icon: String
    let label: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .background(AppTheme.cameraPanel.opacity(0.68), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.10)))
        }
        .accessibilityLabel(label)
    }
}

private struct ScanSpatialOverlay: View {
    let state: ScanVisualizationState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                if state.candidate.count == 4 {
                    let points = state.candidate.map { map($0, size) }
                    let shellOffset = max(12, min(34, CGFloat((state.dimensions?.heightMM ?? 40) / 3.2)))

                    PolygonShape(points: points)
                        .fill(AppTheme.blue.opacity(state.phase == .locked ? 0.10 : 0.055))

                    if state.phase == .buildingEdges || state.phase == .stabilizing || state.phase == .locked {
                        ShellShape(points: points, lift: shellOffset)
                            .fill(AppTheme.cyan.opacity(0.065))
                        ShellShape(points: points, lift: shellOffset)
                            .stroke(AppTheme.cyan.opacity(0.52), lineWidth: 1.3)
                    }

                    CandidateQuadShape(points: points)
                        .trim(from: 0, to: CGFloat(state.edgeProgress))
                        .stroke(
                            state.phase == .locked ? AppTheme.cyan : .white,
                            style: StrokeStyle(lineWidth: state.phase == .locked ? 3 : 2.4, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: state.phase == .locked ? AppTheme.cyan.opacity(0.52) : .black.opacity(0.30), radius: 9)
                        .animation(reduceMotion ? nil : AppMotion.standard, value: state.edgeProgress)

                    ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                        Circle()
                            .fill(state.phase == .locked ? AppTheme.cyan : .white)
                            .frame(width: state.phase == .locked ? 10 : 7, height: state.phase == .locked ? 10 : 7)
                            .shadow(color: AppTheme.cyan.opacity(0.45), radius: 7)
                            .position(point)
                    }

                    if let dimensions = state.dimensions {
                        DimensionOverlay(points: points, dimensions: dimensions, shellOffset: shellOffset)
                            .transition(.opacity)
                    }

                    if state.phase == .locked {
                        Image(systemName: "checkmark")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(.black.opacity(0.82))
                            .frame(width: 40, height: 40)
                            .background(AppTheme.cyan, in: Circle())
                            .position(center(of: points))
                            .transition(.scale.combined(with: .opacity))
                    }
                } else {
                    SearchingPlane()
                        .frame(width: min(size.width * 0.82, 340), height: 220)
                        .position(x: size.width / 2, y: size.height * 0.50)
                }
            }
            .animation(reduceMotion ? nil : AppMotion.spatial, value: state.phase)
        }
        .accessibilityHidden(true)
    }

    private func map(_ point: NormalizedPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: CGFloat(point.x) * size.width, y: CGFloat(point.y) * size.height)
    }

    private func center(of points: [CGPoint]) -> CGPoint {
        CGPoint(
            x: points.map(\.x).reduce(0, +) / CGFloat(points.count),
            y: points.map(\.y).reduce(0, +) / CGFloat(points.count)
        )
    }
}

private struct SearchingPlane: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Ellipse()
                .fill(AppTheme.cyan.opacity(0.045))
            Ellipse()
                .stroke(AppTheme.cyan.opacity(0.52), style: StrokeStyle(lineWidth: 2, dash: [3, 12]))
                .scaleEffect(pulse ? 1 : 0.82)
                .opacity(pulse ? 0.32 : 0.80)
            Image(systemName: "move.3d")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.white.opacity(0.82))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

private struct DimensionOverlay: View {
    let points: [CGPoint]
    let dimensions: BoxDimensions
    let shellOffset: CGFloat

    var body: some View {
        ZStack {
            DimensionLabel(text: dimensions.lengthMM.lengthText, tint: AppTheme.cyan)
                .position(midpoint(points[0], points[1], offsetY: -22))
            DimensionLabel(text: dimensions.widthMM.lengthText, tint: AppTheme.blue)
                .position(midpoint(points[1], points[2], offsetX: 30))
            DimensionLabel(text: dimensions.heightMM.lengthText, tint: AppTheme.amber)
                .position(x: points[2].x + 34, y: points[2].y - shellOffset / 2)
        }
    }

    private func midpoint(_ a: CGPoint, _ b: CGPoint, offsetX: CGFloat = 0, offsetY: CGFloat = 0) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2 + offsetX, y: (a.y + b.y) / 2 + offsetY)
    }
}

private struct DimensionLabel: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold).monospacedDigit())
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(AppTheme.cameraChrome.opacity(0.76), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.38)))
    }
}

private struct CandidateQuadShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() { path.addLine(to: point) }
            path.closeSubpath()
        }
    }
}

private struct ShellShape: Shape {
    let points: [CGPoint]
    let lift: CGFloat

    func path(in rect: CGRect) -> Path {
        guard points.count == 4 else { return Path() }
        let lifted = points.map { CGPoint(x: $0.x, y: $0.y - lift) }
        return Path { path in
            path.move(to: lifted[0])
            path.addLine(to: lifted[1])
            path.addLine(to: points[1])
            path.addLine(to: points[0])
            path.closeSubpath()

            path.move(to: lifted[1])
            path.addLine(to: lifted[2])
            path.addLine(to: points[2])
            path.addLine(to: points[1])
            path.closeSubpath()

            path.move(to: lifted[0])
            for point in lifted.dropFirst() { path.addLine(to: point) }
            path.closeSubpath()
        }
    }
}

private extension Double {
    var lengthText: String {
        LengthUnitPreference.automatic.resolved == .imperial
            ? String(format: "%.1f in", self / 25.4)
            : String(format: "%.1f cm", self / 10)
    }
}
