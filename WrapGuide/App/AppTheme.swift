import SwiftUI
import UIKit

enum AppTheme {
    static let canvas = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.045, green: 0.052, blue: 0.055, alpha: 1)
            : UIColor(red: 0.965, green: 0.951, blue: 0.918, alpha: 1)
    })
    static let surface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.095, green: 0.105, blue: 0.108, alpha: 1)
            : UIColor(red: 1, green: 0.995, blue: 0.978, alpha: 1)
    })
    static let ink = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.96, alpha: 1)
            : UIColor(red: 0.07, green: 0.075, blue: 0.075, alpha: 1)
    })
    static let secondaryInk = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.68, alpha: 1)
            : UIColor(red: 0.35, green: 0.34, blue: 0.31, alpha: 1)
    })
    static let separator = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor.black.withAlphaComponent(0.09)
    })
    static let paper = Color(red: 0.995, green: 0.982, blue: 0.94)
    static let paperEdge = Color(red: 0.73, green: 0.70, blue: 0.62)
    static let blue = Color(red: 0.12, green: 0.38, blue: 0.92)
    static let cyan = Color(red: 0.06, green: 0.72, blue: 0.68)
    static let amber = Color(red: 0.92, green: 0.56, blue: 0.16)
    static let danger = Color(red: 0.86, green: 0.24, blue: 0.22)
}

enum AppMotion {
    static let quick = Animation.easeOut(duration: 0.16)
    static let standard = Animation.easeInOut(duration: 0.25)
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppTheme.blue.opacity(configuration.isPressed ? 0.78 : 1), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(AppMotion.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(AppTheme.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppTheme.blue.opacity(configuration.isPressed ? 0.11 : 0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.blue.opacity(0.20)))
    }
}

struct FixedActionBar<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) { Divider().overlay(AppTheme.separator) }
    }
}

struct PlannerHeader: View {
    let eyebrow: LocalizedStringKey
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(eyebrow)
                .font(.caption.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(AppTheme.blue)
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text(subtitle)
                .font(.body)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatusPill: View {
    let title: LocalizedStringKey
    let tint: Color

    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.11), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.20)))
    }
}

extension View {
    func plannerSurface(padding: CGFloat = 16, radius: CGFloat = 22) -> some View {
        self
            .padding(padding)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(AppTheme.separator))
    }
}
