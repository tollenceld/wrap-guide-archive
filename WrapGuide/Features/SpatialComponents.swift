import SwiftUI

struct BoxDimensionPreview: View {
    let dimensions: BoxDimensions

    var body: some View {
        GeometryReader { proxy in
            let ratio = CGFloat(dimensions.lengthMM / max(dimensions.widthMM, 1)).clamped(to: 1...2.4)
            let width = min(proxy.size.width * 0.64, 230)
            let height = width / ratio

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.separator))

                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(AppTheme.paper)
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppTheme.paperEdge.opacity(0.65), lineWidth: 1.5))
                    .frame(width: width, height: max(72, height))
                    .shadow(color: Color.black.opacity(0.10), radius: 13, y: 8)

                AxisDimension(label: "L", tint: AppTheme.blue)
                    .frame(width: width * 0.92)
                    .offset(y: max(72, height) / 2 + 26)

                AxisDimension(label: "W", tint: AppTheme.cyan)
                    .frame(width: max(72, height) * 0.78)
                    .rotationEffect(.degrees(90))
                    .offset(x: width / 2 + 25)

                Text("H  \(dimensions.heightMM.formattedCentimeters)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(AppTheme.amber)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(AppTheme.amber.opacity(0.10), in: Capsule())
                    .offset(x: -width * 0.28, y: -max(72, height) / 2 - 24)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dimensions.formatted())
    }
}

struct PaperLayoutDiagram: View {
    let plan: PaperPlan
    let dimensions: BoxDimensions

    var body: some View {
        Canvas { context, size in
            let chart = CGRect(x: 18, y: 15, width: size.width - 36, height: size.height - 42)
            let cutWidthMM = plan.rotationDegrees == 90 ? plan.cutSize.heightMM : plan.cutSize.widthMM
            let cutHeightMM = plan.rotationDegrees == 90 ? plan.cutSize.widthMM : plan.cutSize.heightMM
            let maxWidthMM = max(plan.sheetSize.widthMM, cutWidthMM, 1)
            let maxHeightMM = max(plan.sheetSize.heightMM, cutHeightMM, 1)
            let scale = min(chart.width / CGFloat(maxWidthMM), chart.height / CGFloat(maxHeightMM))

            let sheetRect = centeredRect(
                width: CGFloat(max(plan.sheetSize.widthMM, 1)) * scale,
                height: CGFloat(max(plan.sheetSize.heightMM, 1)) * scale,
                in: chart
            )
            let cutRect = centeredRect(
                width: CGFloat(cutWidthMM) * scale,
                height: CGFloat(cutHeightMM) * scale,
                in: chart
            )

            let shadow = Path(roundedRect: sheetRect.offsetBy(dx: 0, dy: 7), cornerRadius: 10)
            context.fill(shadow, with: .color(.black.opacity(0.09)))
            let paper = Path(roundedRect: sheetRect, cornerRadius: 10)
            context.fill(paper, with: .color(AppTheme.paper))
            context.stroke(paper, with: .color(AppTheme.paperEdge.opacity(0.62)), lineWidth: 1.2)

            let target = Path(roundedRect: cutRect, cornerRadius: 8)
            let targetTint = plan.isFeasible ? AppTheme.cyan : AppTheme.danger
            context.stroke(target, with: .color(targetTint), style: StrokeStyle(lineWidth: 2, dash: [7, 5]))

            if plan.isFeasible {
                let horizontalBox = plan.orientation == .longAxis ? dimensions.widthMM : dimensions.lengthMM
                let verticalBox = plan.orientation == .longAxis ? dimensions.lengthMM : dimensions.widthMM
                let rotatedBoxWidth = plan.rotationDegrees == 90 ? verticalBox : horizontalBox
                let rotatedBoxHeight = plan.rotationDegrees == 90 ? horizontalBox : verticalBox
                let boxRect = centeredRect(
                    width: max(35, CGFloat(rotatedBoxWidth) * scale),
                    height: max(48, CGFloat(rotatedBoxHeight) * scale),
                    in: chart
                )
                let box = Path(roundedRect: boxRect, cornerRadius: 7)
                context.fill(box, with: .color(.white.opacity(0.96)))
                context.stroke(box, with: .color(AppTheme.ink.opacity(0.62)), lineWidth: 1.4)

                let endInset = CGFloat(plan.margins.endAllowanceMM) * scale
                for y in [cutRect.minY + endInset, cutRect.maxY - endInset] {
                    var line = Path()
                    line.move(to: CGPoint(x: cutRect.minX + 8, y: y))
                    line.addLine(to: CGPoint(x: cutRect.maxX - 8, y: y))
                    context.stroke(line, with: .color(AppTheme.cyan), style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
                }

                let seamX = cutRect.maxX - CGFloat(plan.margins.seamOverlapMM) * scale
                var seam = Path()
                seam.move(to: CGPoint(x: seamX, y: cutRect.minY + 8))
                seam.addLine(to: CGPoint(x: seamX, y: cutRect.maxY - 8))
                context.stroke(seam, with: .color(AppTheme.amber), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
        }
        .overlay(alignment: .bottom) {
            HStack(spacing: 15) {
                LegendDot(color: plan.isFeasible ? AppTheme.cyan : AppTheme.danger, title: plan.isFeasible ? "diagram.cut" : "diagram.minimum")
                if plan.isFeasible {
                    LegendDot(color: AppTheme.amber, title: "diagram.seam")
                }
            }
            .padding(.bottom, 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(plan.isFeasible ? "diagram.accessible.fit" : "diagram.accessible.insufficient")
    }

    private func centeredRect(width: CGFloat, height: CGFloat, in bounds: CGRect) -> CGRect {
        CGRect(x: bounds.midX - width / 2, y: bounds.midY - height / 2, width: width, height: height)
    }
}

private struct AxisDimension: View {
    let label: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Rectangle().fill(tint).frame(width: 6, height: 1.5)
            Rectangle().fill(tint).frame(height: 1.5)
            Text(label).font(.caption2.weight(.heavy)).foregroundStyle(tint)
            Rectangle().fill(tint).frame(height: 1.5)
            Rectangle().fill(tint).frame(width: 6, height: 1.5)
        }
    }
}

private struct LegendDot: View {
    let color: Color
    let title: LocalizedStringKey

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Circle().fill(color).frame(width: 7, height: 7)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(AppTheme.secondaryInk)
    }
}

private extension Double {
    var formattedCentimeters: String { String(format: "%.1f cm", self / 10) }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
