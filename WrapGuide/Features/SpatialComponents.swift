import SwiftUI

struct StudioBoxView: View {
    let dimensions: BoxDimensions
    var wrapped = false
    var showDimensions = false
    var accent = AppTheme.blue

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let ratio = CGFloat(dimensions.lengthMM / max(dimensions.widthMM, 1)).clamped(to: 1...2.2)
            let width = min(size.width * 0.68, 210)
            let topHeight = width / ratio * 0.52
            let depth = min(max(CGFloat(dimensions.heightMM / max(dimensions.widthMM, 1)) * 74, 30), 72)
            let origin = CGPoint(x: size.width / 2, y: size.height * 0.38)

            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.12))
                    .frame(width: width * 1.08, height: 30)
                    .blur(radius: 8)
                    .position(x: origin.x, y: origin.y + topHeight / 2 + depth + 15)

                PolygonShape(points: [
                    CGPoint(x: origin.x - width / 2, y: origin.y),
                    CGPoint(x: origin.x, y: origin.y + topHeight / 2),
                    CGPoint(x: origin.x, y: origin.y + topHeight / 2 + depth),
                    CGPoint(x: origin.x - width / 2, y: origin.y + depth)
                ])
                .fill(wrapped ? accent.opacity(0.78) : Color(red: 0.78, green: 0.75, blue: 0.68))

                PolygonShape(points: [
                    CGPoint(x: origin.x + width / 2, y: origin.y),
                    CGPoint(x: origin.x, y: origin.y + topHeight / 2),
                    CGPoint(x: origin.x, y: origin.y + topHeight / 2 + depth),
                    CGPoint(x: origin.x + width / 2, y: origin.y + depth)
                ])
                .fill(wrapped ? accent.opacity(0.92) : Color(red: 0.88, green: 0.85, blue: 0.77))

                PolygonShape(points: [
                    CGPoint(x: origin.x, y: origin.y - topHeight / 2),
                    CGPoint(x: origin.x + width / 2, y: origin.y),
                    CGPoint(x: origin.x, y: origin.y + topHeight / 2),
                    CGPoint(x: origin.x - width / 2, y: origin.y)
                ])
                .fill(
                    LinearGradient(
                        colors: wrapped ? [accent.opacity(0.72), accent] : [Color.white, AppTheme.paper],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                if wrapped {
                    Path { path in
                        path.move(to: CGPoint(x: origin.x, y: origin.y - topHeight / 2))
                        path.addLine(to: CGPoint(x: origin.x, y: origin.y + topHeight / 2 + depth))
                    }
                    .stroke(.white.opacity(0.42), lineWidth: 2)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.amber)
                        .frame(width: 24, height: 8)
                        .rotationEffect(.degrees(29))
                        .position(x: origin.x + 12, y: origin.y + topHeight / 2 + depth * 0.55)
                }

                if showDimensions {
                    DimensionCallout(
                        label: dimensions.lengthMM.formattedLength,
                        tint: accent,
                        horizontal: true
                    )
                    .frame(width: width * 0.92)
                    .position(x: origin.x, y: origin.y - topHeight / 2 - 30)

                    DimensionCallout(
                        label: dimensions.widthMM.formattedLength,
                        tint: AppTheme.cyan,
                        horizontal: false
                    )
                    .rotationEffect(.degrees(-29))
                    .frame(width: topHeight * 1.15)
                    .position(x: origin.x - width * 0.39, y: origin.y + topHeight * 0.03)

                    DimensionCallout(
                        label: dimensions.heightMM.formattedLength,
                        tint: AppTheme.amber,
                        horizontal: false
                    )
                    .rotationEffect(.degrees(90))
                    .frame(width: max(depth, 55))
                    .position(x: origin.x + width * 0.47, y: origin.y + topHeight * 0.40 + depth * 0.45)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dimensions.formatted())
    }
}

struct WrappingHeroView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: reduceMotion)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let raw = reduceMotion ? 0.72 : (sin(time * 1.15) + 1) / 2
            let progress = 0.18 + raw * 0.60

            ZStack {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.blue.opacity(0.13), AppTheme.cyan.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Ellipse()
                    .fill(Color.black.opacity(0.14))
                    .frame(width: 222, height: 34)
                    .blur(radius: 12)
                    .offset(y: 66)

                PaperSheetMaterial(feasible: true, recommendsCutting: false)
                    .frame(width: 236, height: 132)
                    .rotationEffect(.degrees(-3))
                    .scaleEffect(x: 0.91 + progress * 0.09, y: 1)

                HStack(spacing: 218) {
                    PaperRollView()
                    PaperRollView(mirrored: true)
                }
                .frame(height: 118)
                .rotationEffect(.degrees(-3))

                AtelierPlanBox(dimensions: .phoneBox)
                    .frame(width: 92, height: 118)
                    .rotationEffect(.degrees(-3))
                    .shadow(color: Color.black.opacity(0.14), radius: 10, y: 8)

                FoldWing(left: true, progress: progress)
                    .fill(AppTheme.blue.opacity(0.22))
                    .overlay(FoldWing(left: true, progress: progress).stroke(AppTheme.blue.opacity(0.72), lineWidth: 2))

                FoldWing(left: false, progress: progress)
                    .fill(AppTheme.cyan.opacity(0.18))
                    .overlay(FoldWing(left: false, progress: progress).stroke(AppTheme.cyan.opacity(0.72), lineWidth: 2))
            }
        }
        .accessibilityHidden(true)
    }
}

struct PaperPlanScene: View {
    let plan: PaperPlan
    let dimensions: BoxDimensions
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var paperRatio: CGFloat {
        CGFloat(plan.sheetSize.widthMM / max(plan.sheetSize.heightMM, 1)).clamped(to: 0.75...1.5)
    }

    var body: some View {
        GeometryReader { proxy in
            let scene = proxy.size
            let paperWidth = min(scene.width * 0.86, 410)
            let paperHeight = min(max(paperWidth / paperRatio, 220), scene.height * 0.68)
            let paperCenter = CGPoint(x: scene.width * 0.45, y: scene.height * 0.50)
            let rollWidth = max(13, paperWidth * 0.045)
            let boxHorizontal = plan.orientation == .longAxis ? dimensions.widthMM : dimensions.lengthMM
            let boxVertical = plan.orientation == .longAxis ? dimensions.lengthMM : dimensions.widthMM
            let boxWidth = max(78, min(paperWidth * 0.58, paperWidth * CGFloat(boxHorizontal / max(plan.cutSize.widthMM, 1))))
            let boxHeight = max(110, min(paperHeight * 0.62, paperHeight * CGFloat(boxVertical / max(plan.cutSize.heightMM, 1))))

            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.16))
                    .frame(width: paperWidth * 0.92, height: paperHeight * 0.16)
                    .blur(radius: 18)
                    .position(x: paperCenter.x, y: paperCenter.y + paperHeight * 0.46)

                PaperSheetMaterial(
                    feasible: plan.isFeasible,
                    recommendsCutting: plan.recommendsCutting
                )
                .frame(width: paperWidth, height: paperHeight)
                .position(paperCenter)

                if plan.isFeasible {
                    EndAllowanceGuide(tint: AppTheme.cyan)
                        .frame(width: paperWidth * 0.78, height: 18)
                        .position(x: paperCenter.x, y: paperCenter.y - paperHeight * 0.31)
                    EndAllowanceGuide(tint: AppTheme.cyan)
                        .frame(width: paperWidth * 0.76, height: 18)
                        .position(x: paperCenter.x, y: paperCenter.y + paperHeight * 0.31)

                    SeamGuide(recommendsCutting: plan.recommendsCutting)
                        .frame(width: 20, height: paperHeight * 0.74)
                        .position(x: paperCenter.x + paperWidth * 0.23, y: paperCenter.y)
                } else {
                    InsufficientTargetShape()
                        .stroke(AppTheme.danger.opacity(0.82), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                        .frame(width: paperWidth * 1.05, height: paperHeight * 1.06)
                        .position(paperCenter)
                }

                AtelierPlanBox(dimensions: dimensions)
                    .frame(width: boxWidth, height: boxHeight)
                    .rotationEffect(.degrees(plan.rotationDegrees))
                    .position(x: paperCenter.x - paperWidth * 0.05, y: paperCenter.y + 3)
                    .animation(reduceMotion ? nil : AppMotion.spatial, value: plan.rotationDegrees)

                PaperRollView()
                    .frame(width: rollWidth, height: paperHeight * 0.90)
                    .rotationEffect(.degrees(-2.2))
                    .position(x: paperCenter.x - paperWidth * 0.50, y: paperCenter.y + paperHeight * 0.01)

                PaperRollView(mirrored: true)
                    .frame(width: rollWidth, height: paperHeight * 0.90)
                    .rotationEffect(.degrees(2.2))
                    .position(x: paperCenter.x + paperWidth * 0.50, y: paperCenter.y - paperHeight * 0.01)

                MarginCallout(value: plan.margins.endAllowanceMM.formattedLength)
                    .position(x: paperCenter.x - paperWidth * 0.29, y: paperCenter.y - paperHeight * 0.47)

                SeamCallout(value: plan.margins.seamOverlapMM.formattedLength)
                    .position(x: paperCenter.x + paperWidth * 0.23, y: paperCenter.y - paperHeight * 0.45)

                EdgeDimensionRuler(label: plan.cutSize.widthMM.formattedLength, axis: .horizontal)
                    .frame(width: paperWidth * 0.92, height: 30)
                    .position(x: paperCenter.x, y: paperCenter.y + paperHeight * 0.55)

                EdgeDimensionRuler(label: plan.cutSize.heightMM.formattedLength, axis: .vertical)
                    .frame(width: 62, height: paperHeight * 0.88)
                    .position(x: paperCenter.x + paperWidth * 0.59, y: paperCenter.y)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(reduceMotion ? nil : AppMotion.spatial, value: plan.id)
        }
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(plan.accessibilitySummary)
    }
}

struct PaperPlanFactBar: View {
    let plan: PaperPlan
    let dimensions: BoxDimensions

    var body: some View {
        HStack(spacing: 14) {
            PlanFactGlyph(kind: .box)
            VStack(alignment: .leading, spacing: 2) {
                Text("paper.boxSize")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                Text(dimensions.formatted())
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            Spacer(minLength: 6)
            Divider().frame(height: 34)
            PlanFactGlyph(kind: .seam)
            VStack(alignment: .leading, spacing: 2) {
                Text("paper.overlap")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                Text(plan.margins.seamOverlapMM.formattedLength)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .background(AppTheme.surface.opacity(0.94), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.separator))
    }
}

struct PaperPlanGlyph: View {
    let strategy: PaperStrategy
    var selected = false

    var body: some View {
        Canvas { context, size in
            let tint = selected ? AppTheme.blue : AppTheme.secondaryInk.opacity(0.72)
            let paperRect = CGRect(x: size.width * 0.16, y: size.height * 0.17, width: size.width * 0.68, height: size.height * 0.66)
            let paper = Path(roundedRect: paperRect, cornerRadius: 4)
            context.fill(paper, with: .color(AppTheme.paperBright))
            context.stroke(paper, with: .color(tint), lineWidth: 1.5)

            switch strategy {
            case .easyWrap:
                let box = Path(roundedRect: paperRect.insetBy(dx: size.width * 0.19, dy: size.height * 0.16), cornerRadius: 2)
                context.fill(box, with: .color(tint.opacity(0.15)))
                context.stroke(box, with: .color(tint), lineWidth: 1.2)
                for x in [paperRect.minX + paperRect.width * 0.24, paperRect.maxX - paperRect.width * 0.24] {
                    var line = Path()
                    line.move(to: CGPoint(x: x, y: paperRect.minY))
                    line.addLine(to: CGPoint(x: x, y: paperRect.maxY))
                    context.stroke(line, with: .color(AppTheme.cyan), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            case .justFit:
                let boxRect = paperRect.insetBy(dx: size.width * 0.10, dy: size.height * 0.10)
                let box = Path(roundedRect: boxRect, cornerRadius: 2)
                context.fill(box, with: .color(tint.opacity(0.10)))
                context.stroke(box, with: .color(tint), lineWidth: 1.2)
                var fold = Path()
                fold.move(to: CGPoint(x: boxRect.minX, y: boxRect.midY))
                fold.addLine(to: CGPoint(x: boxRect.maxX, y: boxRect.midY))
                context.stroke(fold, with: .color(AppTheme.cyan), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            case .custom:
                let inset = Path(roundedRect: paperRect.insetBy(dx: 7, dy: 5), cornerRadius: 2)
                context.stroke(inset, with: .color(tint), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                var plus = Path()
                plus.move(to: CGPoint(x: paperRect.midX, y: paperRect.midY - 7))
                plus.addLine(to: CGPoint(x: paperRect.midX, y: paperRect.midY + 7))
                plus.move(to: CGPoint(x: paperRect.midX - 7, y: paperRect.midY))
                plus.addLine(to: CGPoint(x: paperRect.midX + 7, y: paperRect.midY))
                context.stroke(plus, with: .color(tint), lineWidth: 1.5)
            }
        }
        .frame(width: 48, height: 40)
        .accessibilityHidden(true)
    }
}

private struct PaperSheetMaterial: View {
    let feasible: Bool
    let recommendsCutting: Bool

    var body: some View {
        ZStack {
            PaperPerspectiveShape()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.paperBright, AppTheme.paperMid, AppTheme.paperBright.opacity(0.96)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.12), radius: 13, x: 0, y: 9)

            PaperFiberField(opacity: 0.10)
                .clipShape(PaperPerspectiveShape())

            if recommendsCutting {
                PaperPerspectiveShape()
                    .inset(by: 12)
                    .stroke(AppTheme.amber.opacity(0.78), style: StrokeStyle(lineWidth: 1.5, dash: [7, 6]))
            }

            PaperPerspectiveShape()
                .stroke(feasible ? Color.white.opacity(0.82) : AppTheme.danger.opacity(0.55), lineWidth: 1)
        }
    }
}

private struct PaperFiberField: View {
    let opacity: Double

    var body: some View {
        Canvas { context, size in
            for index in 0..<28 {
                let y = size.height * CGFloat(index + 1) / 29
                let phase = CGFloat((index * 17) % 11) / 11
                var strand = Path()
                strand.move(to: CGPoint(x: -8, y: y))
                strand.addCurve(
                    to: CGPoint(x: size.width + 8, y: y + sin(phase * .pi * 2) * 1.6),
                    control1: CGPoint(x: size.width * 0.31, y: y - 1.4),
                    control2: CGPoint(x: size.width * 0.68, y: y + 1.2)
                )
                context.stroke(strand, with: .color(AppTheme.paperFiber.opacity(opacity)), lineWidth: 0.45)
            }
            for index in 0..<18 {
                let x = size.width * CGFloat(index + 1) / 19
                var strand = Path()
                strand.move(to: CGPoint(x: x, y: -4))
                strand.addLine(to: CGPoint(x: x + CGFloat(index.isMultiple(of: 2) ? 1 : -1), y: size.height + 4))
                context.stroke(strand, with: .color(Color.white.opacity(opacity * 1.6)), lineWidth: 0.35)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct PaperPerspectiveShape: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        return Path { path in
            path.move(to: CGPoint(x: r.minX + r.width * 0.045, y: r.minY + r.height * 0.035))
            path.addLine(to: CGPoint(x: r.maxX - r.width * 0.035, y: r.minY))
            path.addLine(to: CGPoint(x: r.maxX, y: r.maxY - r.height * 0.035))
            path.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            path.closeSubpath()
        }
    }

    func inset(by amount: CGFloat) -> PaperPerspectiveShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

private struct PaperRollView: View {
    var mirrored = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: mirrored ? .trailing : .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: mirrored
                                ? [AppTheme.paperEdge.opacity(0.78), AppTheme.paperBright, AppTheme.paperMid]
                                : [AppTheme.paperMid, AppTheme.paperBright, AppTheme.paperEdge.opacity(0.78)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.14), radius: 5, x: mirrored ? -3 : 3, y: 4)

                Ellipse()
                    .fill(Color.black.opacity(0.10))
                    .overlay(Ellipse().stroke(AppTheme.paperEdge.opacity(0.72), lineWidth: 0.8))
                    .frame(width: proxy.size.width * 0.92, height: proxy.size.width * 0.48)
                    .offset(y: proxy.size.height * 0.44)
            }
        }
    }
}

private struct AtelierPlanBox: View {
    let dimensions: BoxDimensions

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.black.opacity(0.20))
                .blur(radius: 10)
                .offset(y: 13)
                .scaleEffect(x: 0.93, y: 0.92)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.paperEdge.opacity(0.58))
                .offset(y: 6)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white, AppTheme.paperBright, AppTheme.paperMid.opacity(0.88)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(PaperFiberField(opacity: 0.07).clipShape(RoundedRectangle(cornerRadius: 8)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.86), lineWidth: 1))

            VStack {
                Spacer()
                HStack(spacing: 0) {
                    TriangleFoldShape(left: true)
                        .stroke(AppTheme.paperEdge.opacity(0.46), lineWidth: 0.8)
                    TriangleFoldShape(left: false)
                        .stroke(AppTheme.paperEdge.opacity(0.46), lineWidth: 0.8)
                }
                .frame(height: 24)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct TriangleFoldShape: Shape {
    let left: Bool

    func path(in rect: CGRect) -> Path {
        Path { path in
            if left {
                path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            } else {
                path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            }
        }
    }
}

private struct EndAllowanceGuide: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle().fill(tint.opacity(0.07))
                Path { path in
                    path.move(to: CGPoint(x: 0, y: proxy.size.height / 2))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height / 2))
                }
                .stroke(tint.opacity(0.90), style: StrokeStyle(lineWidth: 1.5, dash: [7, 5]))
            }
        }
    }
}

private struct SeamGuide: View {
    let recommendsCutting: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(AppTheme.amber.opacity(recommendsCutting ? 0.14 : 0.08))
                Path { path in
                    path.move(to: CGPoint(x: proxy.size.width / 2, y: 0))
                    path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height))
                }
                .stroke(AppTheme.amber.opacity(0.92), style: StrokeStyle(lineWidth: 1.6, dash: [7, 5]))
            }
        }
    }
}

private struct MarginCallout: View {
    let value: String

    var body: some View {
        VStack(spacing: 1) {
            Text("paper.margin.end")
                .font(.caption2.weight(.semibold))
            Text(value)
                .font(.caption.weight(.bold).monospacedDigit())
        }
        .foregroundStyle(AppTheme.cyan)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(AppTheme.surface.opacity(0.94), in: Capsule())
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }
}

private struct SeamCallout: View {
    let value: String

    var body: some View {
        VStack(spacing: 1) {
            Text("paper.margin.seam")
                .font(.caption2.weight(.semibold))
            Text(value)
                .font(.caption.weight(.bold).monospacedDigit())
        }
        .foregroundStyle(AppTheme.amber)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(AppTheme.surface.opacity(0.94), in: Capsule())
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }
}

private enum RulerAxis { case horizontal, vertical }

private struct EdgeDimensionRuler: View {
    let label: String
    let axis: RulerAxis

    var body: some View {
        GeometryReader { proxy in
            let isHorizontal = axis == .horizontal
            ZStack {
                Path { path in
                    if isHorizontal {
                        path.move(to: CGPoint(x: 4, y: proxy.size.height / 2))
                        path.addLine(to: CGPoint(x: proxy.size.width - 4, y: proxy.size.height / 2))
                        path.move(to: CGPoint(x: 4, y: 4))
                        path.addLine(to: CGPoint(x: 4, y: proxy.size.height - 4))
                        path.move(to: CGPoint(x: proxy.size.width - 4, y: 4))
                        path.addLine(to: CGPoint(x: proxy.size.width - 4, y: proxy.size.height - 4))
                    } else {
                        path.move(to: CGPoint(x: proxy.size.width / 2, y: 4))
                        path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height - 4))
                        path.move(to: CGPoint(x: 4, y: 4))
                        path.addLine(to: CGPoint(x: proxy.size.width - 4, y: 4))
                        path.move(to: CGPoint(x: 4, y: proxy.size.height - 4))
                        path.addLine(to: CGPoint(x: proxy.size.width - 4, y: proxy.size.height - 4))
                    }
                }
                .stroke(AppTheme.blue.opacity(0.90), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))

                Text(axis == .horizontal ? label : label.replacingOccurrences(of: " ", with: "\n"))
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(AppTheme.blue)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.canvas.opacity(0.94), in: Capsule())
            }
        }
    }
}

private struct InsufficientTargetShape: Shape {
    func path(in rect: CGRect) -> Path {
        RoundedRectangle(cornerRadius: 18).path(in: rect)
    }
}

private enum PlanFactKind { case box, seam }

private struct PlanFactGlyph: View {
    let kind: PlanFactKind

    var body: some View {
        Canvas { context, size in
            switch kind {
            case .box:
                let rect = CGRect(x: 4, y: 5, width: size.width - 8, height: size.height - 10)
                let path = Path(roundedRect: rect, cornerRadius: 4)
                context.fill(path, with: .color(AppTheme.paperBright))
                context.stroke(path, with: .color(AppTheme.secondaryInk.opacity(0.72)), lineWidth: 1.4)
                var seam = Path()
                seam.move(to: CGPoint(x: rect.midX, y: rect.minY))
                seam.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
                context.stroke(seam, with: .color(AppTheme.secondaryInk.opacity(0.50)), lineWidth: 1)
            case .seam:
                let outer = Path(ellipseIn: CGRect(x: 3, y: 3, width: size.height - 6, height: size.height - 6))
                context.stroke(outer, with: .color(AppTheme.secondaryInk.opacity(0.72)), lineWidth: 1.5)
                let inner = Path(ellipseIn: CGRect(x: 10, y: 10, width: size.height - 20, height: size.height - 20))
                context.stroke(inner, with: .color(AppTheme.secondaryInk.opacity(0.40)), lineWidth: 1.2)
                let tail = CGRect(x: size.width * 0.54, y: size.height * 0.55, width: size.width * 0.40, height: 7)
                let tailPath = Path(roundedRect: tail, cornerRadius: 2)
                context.fill(tailPath, with: .color(AppTheme.amber.opacity(0.60)))
            }
        }
        .frame(width: 38, height: 34)
        .accessibilityHidden(true)
    }
}

struct PreparationWorkspaceView: View {
    let dimensions: BoxDimensions

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.surface, AppTheme.blue.opacity(0.055)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    )

            Ellipse()
                .fill(Color.black.opacity(0.13))
                .frame(width: 264, height: 34)
                .blur(radius: 13)
                .offset(y: 55)

            PaperSheetMaterial(feasible: true, recommendsCutting: false)
                .frame(width: 272, height: 158)
                .rotationEffect(.degrees(-3))

            HStack(spacing: 252) {
                PaperRollView()
                PaperRollView(mirrored: true)
            }
            .frame(height: 142)
            .rotationEffect(.degrees(-3))

            EndAllowanceGuide(tint: AppTheme.cyan)
                .frame(width: 206, height: 14)
                .offset(y: -48)

            AtelierPlanBox(dimensions: dimensions)
                .frame(width: 96, height: 122)
                .rotationEffect(.degrees(-3))
                .offset(y: -2)
                .shadow(color: Color.black.opacity(0.14), radius: 10, y: 7)

            HStack(spacing: 20) {
                WorkspaceTool(icon: "scissors", label: "prepare.scissors")
                WorkspaceTool(icon: "bandage", label: "prepare.tape")
            }
            .offset(y: 102)
        }
        .accessibilityElement(children: .combine)
    }
}

struct CompletedGiftView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.cyan.opacity(0.09))
                .frame(width: 250, height: 250)
                .scaleEffect(appeared ? 1 : 0.84)

            StudioBoxView(dimensions: .phoneBox, wrapped: true, accent: AppTheme.blue)
                .frame(width: 310, height: 235)
                .offset(y: 3)
                .scaleEffect(appeared ? 1 : 0.88)
                .opacity(appeared ? 1 : 0)

            if appeared {
                Circle()
                    .trim(from: 0, to: 0.82)
                    .stroke(AppTheme.cyan.opacity(0.50), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [3, 10]))
                    .frame(width: 230, height: 230)
                    .rotationEffect(.degrees(-76))
                    .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : AppMotion.settle) {
                appeared = true
            }
        }
        .accessibilityHidden(true)
    }
}

private struct DimensionCallout: View {
    let label: String
    let tint: Color
    let horizontal: Bool

    var body: some View {
        HStack(spacing: 5) {
            Rectangle().fill(tint).frame(width: 5, height: 1)
            Rectangle().fill(tint).frame(height: 1)
            Text(label)
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
                .fixedSize()
            Rectangle().fill(tint).frame(height: 1)
            Rectangle().fill(tint).frame(width: 5, height: 1)
        }
        .opacity(horizontal ? 1 : 0.95)
    }
}

private struct FoldAllowanceLine: View {
    let label: LocalizedStringKey
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tint)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(AppTheme.surface.opacity(0.86), in: Capsule())
            Rectangle()
                .fill(tint)
                .frame(width: 1.5)
                .overlay {
                    Rectangle()
                        .stroke(tint, style: StrokeStyle(lineWidth: 2, dash: [8, 7]))
                }
        }
        .padding(.vertical, 12)
    }
}

private struct WorkspaceTool: View {
    let icon: String
    let label: LocalizedStringKey

    var body: some View {
        Label(label, systemImage: icon)
            .labelStyle(.iconOnly)
            .font(.title3)
            .foregroundStyle(AppTheme.blue)
            .frame(width: 44, height: 44)
            .background(AppTheme.surface, in: Circle())
            .overlay(Circle().stroke(AppTheme.separator))
    }
}

private struct FoldWing: Shape {
    let left: Bool
    let progress: Double

    func path(in rect: CGRect) -> Path {
        let direction: CGFloat = left ? -1 : 1
        let center = CGPoint(x: rect.midX, y: rect.midY + 12)
        let spread = CGFloat(1 - progress) * 46 + 22
        return Path { path in
            path.move(to: CGPoint(x: center.x + direction * 28, y: center.y - 44))
            path.addLine(to: CGPoint(x: center.x + direction * (42 + spread), y: center.y - 12))
            path.addLine(to: CGPoint(x: center.x + direction * (38 + spread), y: center.y + 48))
            path.addLine(to: CGPoint(x: center.x + direction * 24, y: center.y + 34))
            path.closeSubpath()
        }
    }
}

struct PolygonShape: Shape {
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

private struct PaperGrid: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            stride(from: 0.0, through: rect.width, by: 22).forEach { x in
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: rect.height))
            }
            stride(from: 0.0, through: rect.height, by: 22).forEach { y in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: rect.width, y: y))
            }
        }
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

private extension Double {
    var formattedLength: String {
        LengthUnitPreference.automatic.resolved == .imperial
            ? String(format: "%.1f in", self / 25.4)
            : String(format: "%.1f cm", self / 10)
    }
}

extension PaperDifficulty {
    var localizedKey: LocalizedStringKey {
        switch self {
        case .roomy: "difficulty.roomy"
        case .comfortable: "difficulty.comfortable"
        case .precise: "difficulty.precise"
        case .insufficient: "difficulty.insufficient"
        }
    }
}

private extension PaperPlan {
    var accessibilitySummary: String {
        "\(cutSize.formatted()), \(String(format: "%.0f", wasteRatio * 100))%"
    }
}
