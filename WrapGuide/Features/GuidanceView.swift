import AVFoundation
import SwiftUI

struct GuidanceView: View {
    let coordinator: AppCoordinator
    private let method = StandardBoxWrapMethod()
    @State private var relockToken = UUID()
    @State private var confirmSkip = false
    @AppStorage("voicePrompts") private var voicePrompts = false
    @AccessibilityFocusState private var stepHeadingFocused: Bool

    private var step: GuidanceStep {
        method.steps[min(max(0, coordinator.currentStep), method.steps.count - 1)]
    }

    var body: some View {
        ZStack {
            GuidanceCameraView(
                step: step,
                dimensions: coordinator.dimensions,
                relockToken: relockToken
            )
            .id(step.id)
            .transition(.opacity)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                guidanceHeader
                Spacer()
                guidancePanel
            }
        }
        .background(AppTheme.cameraChrome)
        .toolbar(.hidden, for: .navigationBar)
        .alert("guide.skip.title", isPresented: $confirmSkip) {
            Button("action.cancel", role: .cancel) {}
            Button("guide.skip", role: .destructive) { coordinator.nextGuidanceStep() }
        } message: {
            Text("guide.skip.message")
        }
        .onAppear { announceStep() }
        .onChange(of: coordinator.currentStep) { _, _ in
            stepHeadingFocused = true
            announceStep()
        }
    }

    private var guidanceHeader: some View {
        HStack(spacing: 12) {
            CameraCircleButton(icon: "xmark", label: "action.close") {
                coordinator.goHome()
            }

            PhaseProgressView(step: step, allSteps: method.steps)

            CameraCircleButton(icon: "viewfinder", label: "guide.relock") {
                AppHaptics.impact()
                relockToken = UUID()
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 5)
    }

    private var guidancePanel: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(step.phase.titleKey))
                        .font(.caption.weight(.bold))
                        .tracking(0.8)
                        .foregroundStyle(AppTheme.cyan)
                    Text(LocalizedStringKey(step.titleKey))
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .accessibilityFocused($stepHeadingFocused)
                }
                Spacer()

                Text("\(step.id)")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.blue.opacity(0.72), in: Circle())
            }

            Text(LocalizedStringKey(step.instructionKey))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if step.requiresRelock {
                Label("guide.relockNeeded", systemImage: "scope")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.amber)
            } else if coordinator.mode == .handheld {
                Label("guide.handheldHint", systemImage: "hand.raised.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.52))
            }

            HStack(spacing: 10) {
                Button {
                    AppHaptics.selection()
                    coordinator.previousGuidanceStep()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 48)
                }
                .buttonStyle(CameraButtonStyle())
                .frame(width: 64)
                .disabled(coordinator.currentStep == 0)
                .accessibilityLabel(Text("guide.previous"))

                Button(coordinator.currentStep == method.steps.count - 1 ? "guide.finish" : "guide.done") {
                    AppHaptics.impact()
                    coordinator.nextGuidanceStep()
                }
                .buttonStyle(CameraButtonStyle(prominent: true))
                .accessibilityIdentifier("guidanceDoneButton")

                Menu {
                    Button("guide.skip", role: .destructive) { confirmSkip = true }
                    Button("guide.relock") { relockToken = UUID() }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 48)
                }
                .buttonStyle(CameraButtonStyle())
                .frame(width: 64)
                .accessibilityLabel(Text("action.more"))
            }
        }
        .cameraSurface(padding: 17, radius: 26)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private func announceStep() {
        guard voicePrompts else { return }
        let title = String(localized: String.LocalizationValue(step.titleKey))
        let instruction = String(localized: String.LocalizationValue(step.instructionKey))
        let utterance = AVSpeechUtterance(string: "\(title). \(instruction)")
        utterance.rate = 0.48
        AVSpeechSynthesizer().speak(utterance)
    }
}

private struct CameraCircleButton: View {
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
                .background(AppTheme.cameraPanel.opacity(0.72), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.10)))
        }
        .accessibilityLabel(label)
    }
}

private struct PhaseProgressView: View {
    let step: GuidanceStep
    let allSteps: [GuidanceStep]

    private var phaseIndex: Int {
        WrapPhase.allCases.firstIndex(of: step.phase) ?? 0
    }

    private var phaseSteps: [GuidanceStep] {
        allSteps.filter { $0.phase == step.phase }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                ForEach(Array(WrapPhase.allCases.enumerated()), id: \.element) { index, _ in
                    Capsule()
                        .fill(index <= phaseIndex ? AppTheme.cyan : Color.white.opacity(0.18))
                        .frame(height: index == phaseIndex ? 5 : 3)
                }
            }

            HStack(spacing: 6) {
                Text(LocalizedStringKey(step.phase.titleKey))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                ForEach(phaseSteps) { phaseStep in
                    Circle()
                        .fill(phaseStep.id <= step.id ? AppTheme.cyan : Color.white.opacity(0.22))
                        .frame(width: 5, height: 5)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(.ultraThinMaterial, in: Capsule())
        .background(AppTheme.cameraPanel.opacity(0.72), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.10)))
    }
}

struct GuidanceDiagramView: View {
    let step: GuidanceStep
    let dimensions: BoxDimensions
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
            GeometryReader { proxy in
                let progress = animationProgress(at: context.date)
                let size = proxy.size

                ZStack {
                    LinearGradient(
                        colors: [Color.black, AppTheme.cameraChrome, Color(red: 0.02, green: 0.05, blue: 0.07)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    RadialGradient(
                        colors: [AppTheme.blue.opacity(0.11), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: min(size.width, size.height) * 0.62
                    )

                    GuidanceMaterialStage()
                        .frame(width: size.width * 0.90, height: size.height * 0.78)
                        .position(x: size.width * 0.5, y: size.height * 0.49)

                    ForEach(Array(step.primitives.enumerated()), id: \.offset) { _, primitive in
                        primitiveView(primitive, size: size, progress: progress)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(LocalizedStringKey(step.instructionKey)))
    }

    @ViewBuilder
    private func primitiveView(_ primitive: OverlayPrimitive, size: CGSize, progress: Float) -> some View {
        switch primitive {
        case .boxOutline:
            GuidanceBoxSurface(dimensions: dimensions, viewpoint: step.viewpoint)
                .frame(width: size.width * 0.48, height: size.height * (step.viewpoint == .endFace ? 0.31 : 0.27))
                .position(x: size.width * 0.5, y: size.height * 0.47)

        case .ghostBox:
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.cyan.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.cyan.opacity(0.84), style: StrokeStyle(lineWidth: 2, dash: [8, 6])))
                .frame(width: size.width * 0.52, height: size.height * 0.27)
                .position(x: size.width * 0.5, y: size.height * 0.47)
                .opacity(0.50 + Double(progress) * 0.42)

        case let .paperSurface(points, role):
            let mapped = points.map { point($0, size) }
            PolygonShape(points: mapped)
                .fill(fill(for: role))
                .overlay(GuidanceFiberTexture().clipShape(PolygonShape(points: mapped)).opacity(role == .active ? 0.18 : 0.10))
                .overlay(PolygonShape(points: mapped).stroke(stroke(for: role), lineWidth: role == .active ? 2 : 1.25))
                .shadow(color: role == .active ? AppTheme.blue.opacity(0.18) : Color.black.opacity(0.08), radius: role == .active ? 10 : 4, y: 3)

        case let .paperFlap(start, end):
            let points = interpolated(start: start, end: end, progress: progress).map { point($0, size) }
            PolygonShape(points: points)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.blue.opacity(0.62), AppTheme.blue.opacity(0.28)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(GuidanceFiberTexture().clipShape(PolygonShape(points: points)).opacity(0.22))
                .overlay(PolygonShape(points: points).stroke(AppTheme.blue.opacity(0.95), lineWidth: 2))
                .shadow(color: Color.black.opacity(0.24), radius: 11, y: 7)

        case let .targetRegion(points):
            PolygonShape(points: points.map { point($0, size) })
                .fill(AppTheme.cyan.opacity(0.16))
                .overlay(PolygonShape(points: points.map { point($0, size) }).stroke(AppTheme.cyan.opacity(0.88), style: StrokeStyle(lineWidth: 1.8, dash: [7, 5])))

        case let .foldLine(from, to):
            let start = point(from, size)
            let end = point(to, size)
            GuideLine(from: start, to: end)
                .stroke(AppTheme.cyan, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [8, 5]))
                .overlay(FoldAxisCaps(from: start, to: end).stroke(AppTheme.cyan, style: StrokeStyle(lineWidth: 1.5, lineCap: .round)))

        case let .alignmentLine(from, to):
            GuideLine(from: point(from, size), to: point(to, size))
                .stroke(.white.opacity(0.82), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .shadow(color: AppTheme.cyan.opacity(0.42), radius: 4)

        case let .motionPath(points):
            let mapped = points.map { point($0, size) }
            MotionPathShape(points: mapped)
                .stroke(AppTheme.blue.opacity(0.92), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [8, 8]))
                .overlay {
                    if let moving = movingPoint(on: mapped, progress: progress) {
                        Circle()
                            .fill(.white)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(AppTheme.blue, lineWidth: 3))
                            .shadow(color: AppTheme.blue.opacity(0.55), radius: 6)
                            .position(moving)
                    }
                }
                .overlay {
                    if let last = mapped.last, mapped.count > 1 {
                        MotionArrowHead(from: mapped[mapped.count - 2], to: last)
                            .stroke(AppTheme.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                }

        case let .tape(at, angleDegrees):
            TapeStripShape()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.amber.opacity(0.68), AppTheme.amber.opacity(0.94)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 44, height: 17)
                .rotationEffect(.degrees(Double(angleDegrees)))
                .position(point(at, size))
                .scaleEffect(0.88 + CGFloat(progress) * 0.12)
                .shadow(color: Color.black.opacity(0.22), radius: 4, y: 3)
        }
    }

    private func animationProgress(at date: Date) -> Float {
        guard !reduceMotion else { return 0.72 }
        let cycle = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.35) / 2.35
        if cycle < 0.16 { return 0 }
        if cycle > 0.76 { return 1 }
        let normalized = Float((cycle - 0.16) / 0.60)
        return normalized * normalized * (3 - 2 * normalized)
    }

    private func point(_ point: NormalizedPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: CGFloat(point.x) * size.width, y: CGFloat(point.y) * size.height)
    }

    private func interpolated(start: [NormalizedPoint], end: [NormalizedPoint], progress: Float) -> [NormalizedPoint] {
        zip(start, end).map { $0.interpolated(to: $1, progress: progress) }
    }

    private func fill(for role: PaperLayerRole) -> Color {
        switch role {
        case .context: AppTheme.paperBright.opacity(0.90)
        case .active: AppTheme.blue.opacity(0.38)
        case .target: AppTheme.cyan.opacity(0.16)
        case .completed: AppTheme.paperMid.opacity(0.90)
        }
    }

    private func stroke(for role: PaperLayerRole) -> Color {
        switch role {
        case .context: AppTheme.paperEdge.opacity(0.58)
        case .active: AppTheme.blue
        case .target: AppTheme.cyan
        case .completed: Color.white.opacity(0.70)
        }
    }

    private func movingPoint(on points: [CGPoint], progress: Float) -> CGPoint? {
        guard points.count > 1 else { return points.first }
        let segment = min(Int(progress * Float(points.count - 1)), points.count - 2)
        let local = progress * Float(points.count - 1) - Float(segment)
        let start = points[segment]
        let end = points[segment + 1]
        return CGPoint(
            x: start.x + (end.x - start.x) * CGFloat(local),
            y: start.y + (end.y - start.y) * CGFloat(local)
        )
    }
}

private struct GuideLine: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
    }
}

private struct GuideBoxShape: Shape {
    func path(in rect: CGRect) -> Path {
        RoundedRectangle(cornerRadius: 14, style: .continuous).path(in: rect)
    }
}

private struct MotionPathShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            guard points.count > 2 else {
                if let last = points.last { path.addLine(to: last) }
                return
            }

            for index in 1..<(points.count - 1) {
                let control = points[index]
                let next = points[index + 1]
                let midpoint = CGPoint(x: (control.x + next.x) / 2, y: (control.y + next.y) / 2)
                path.addQuadCurve(to: midpoint, control: control)
            }
            if let penultimate = points.dropLast().last, let last = points.last {
                path.addQuadCurve(to: last, control: penultimate)
            }
        }
    }
}

private struct MotionArrowHead: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let length: CGFloat = 15
        return Path { path in
            path.move(to: to)
            path.addLine(to: CGPoint(x: to.x - length * cos(angle - .pi / 5), y: to.y - length * sin(angle - .pi / 5)))
            path.move(to: to)
            path.addLine(to: CGPoint(x: to.x - length * cos(angle + .pi / 5), y: to.y - length * sin(angle + .pi / 5)))
        }
    }
}

private struct GuidanceMaterialStage: View {
    var body: some View {
        GeometryReader { proxy in
            let rollWidth = max(12, proxy.size.width * 0.04)
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.black.opacity(0.38))
                    .blur(radius: 18)
                    .offset(y: 14)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.paperBright.opacity(0.96), AppTheme.paperMid.opacity(0.94)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(GuidanceFiberTexture().clipShape(RoundedRectangle(cornerRadius: 18)).opacity(0.09))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.68), lineWidth: 1))
                    .padding(.horizontal, rollWidth * 0.40)

                HStack {
                    GuidanceRollEdge()
                        .frame(width: rollWidth)
                    Spacer()
                    GuidanceRollEdge(mirrored: true)
                        .frame(width: rollWidth)
                }
                .padding(.vertical, proxy.size.height * 0.035)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct GuidanceRollEdge: View {
    var mirrored = false

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: mirrored
                        ? [AppTheme.paperEdge.opacity(0.86), AppTheme.paperBright, AppTheme.paperMid]
                        : [AppTheme.paperMid, AppTheme.paperBright, AppTheme.paperEdge.opacity(0.86)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: Color.black.opacity(0.22), radius: 5, x: mirrored ? -3 : 3, y: 3)
    }
}

private struct GuidanceBoxSurface: View {
    let dimensions: BoxDimensions
    let viewpoint: GuidanceViewpoint

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.black.opacity(0.30))
                .blur(radius: 12)
                .offset(y: 12)
                .scaleEffect(x: 0.94, y: 0.92)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.paperEdge.opacity(0.62))
                .offset(y: 6)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.98), AppTheme.paperBright, AppTheme.paperMid.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(GuidanceFiberTexture().clipShape(RoundedRectangle(cornerRadius: 10)).opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.90), lineWidth: 1.6))

            if viewpoint == .endFace {
                VStack {
                    Spacer()
                    HStack(spacing: 0) {
                        EndFaceCrease(left: true)
                            .stroke(AppTheme.paperEdge.opacity(0.58), lineWidth: 1)
                        EndFaceCrease(left: false)
                            .stroke(AppTheme.paperEdge.opacity(0.58), lineWidth: 1)
                    }
                    .frame(height: 38)
                }
            }
        }
        .shadow(color: AppTheme.blue.opacity(0.10), radius: 16)
        .accessibilityLabel(dimensions.formatted())
    }
}

private struct EndFaceCrease: Shape {
    let left: Bool

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: left ? rect.minX : rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: left ? rect.maxX : rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: left ? rect.maxX : rect.minX, y: rect.maxY))
        }
    }
}

private struct GuidanceFiberTexture: View {
    var body: some View {
        Canvas { context, size in
            for index in 0..<24 {
                let y = size.height * CGFloat(index + 1) / 25
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addCurve(
                    to: CGPoint(x: size.width, y: y + CGFloat(index.isMultiple(of: 2) ? 1 : -1)),
                    control1: CGPoint(x: size.width * 0.34, y: y - 1),
                    control2: CGPoint(x: size.width * 0.66, y: y + 1)
                )
                context.stroke(line, with: .color(AppTheme.paperFiber.opacity(0.36)), lineWidth: 0.45)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct FoldAxisCaps: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        let angle = atan2(to.y - from.y, to.x - from.x) + .pi / 2
        let length: CGFloat = 8
        return Path { path in
            for point in [from, to] {
                path.move(to: CGPoint(x: point.x - cos(angle) * length, y: point.y - sin(angle) * length))
                path.addLine(to: CGPoint(x: point.x + cos(angle) * length, y: point.y + sin(angle) * length))
            }
        }
    }
}

private struct TapeStripShape: Shape {
    func path(in rect: CGRect) -> Path {
        let teeth = 5
        return Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + 2))
            for index in 0...teeth {
                let y = rect.minY + rect.height * CGFloat(index) / CGFloat(teeth)
                path.addLine(to: CGPoint(x: rect.minX + (index.isMultiple(of: 2) ? 2 : 0), y: y))
            }
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 2))
            for index in stride(from: teeth, through: 0, by: -1) {
                let y = rect.minY + rect.height * CGFloat(index) / CGFloat(teeth)
                path.addLine(to: CGPoint(x: rect.maxX - (index.isMultiple(of: 2) ? 2 : 0), y: y))
            }
            path.closeSubpath()
        }
    }
}
