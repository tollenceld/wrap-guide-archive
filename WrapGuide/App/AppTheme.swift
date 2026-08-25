import SwiftUI
import UIKit

enum AppTheme {
    static let canvas = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.035, green: 0.047, blue: 0.055, alpha: 1)
            : UIColor(red: 0.965, green: 0.949, blue: 0.914, alpha: 1)
    })
    static let surface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.085, green: 0.102, blue: 0.112, alpha: 1)
            : UIColor(red: 1.0, green: 0.995, blue: 0.975, alpha: 1)
    })
    static let elevatedSurface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.115, green: 0.132, blue: 0.142, alpha: 1)
            : UIColor.white
    })
    static let ink = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.97, alpha: 1)
            : UIColor(red: 0.055, green: 0.075, blue: 0.082, alpha: 1)
    })
    static let secondaryInk = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.72, alpha: 1)
            : UIColor(red: 0.29, green: 0.31, blue: 0.31, alpha: 1)
    })
    static let separator = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor(red: 0.08, green: 0.10, blue: 0.11, alpha: 0.10)
    })

    static let cameraChrome = Color(red: 0.025, green: 0.035, blue: 0.042)
    static let cameraPanel = Color(red: 0.055, green: 0.067, blue: 0.073).opacity(0.94)
    static let paper = Color(red: 0.94, green: 0.91, blue: 0.84)
    static let paperBright = Color(red: 0.995, green: 0.986, blue: 0.955)
    static let paperMid = Color(red: 0.93, green: 0.91, blue: 0.86)
    static let paperEdge = Color(red: 0.76, green: 0.73, blue: 0.66)
    static let paperFiber = Color(red: 0.42, green: 0.39, blue: 0.33)
    static let cyan = Color(red: 0.13, green: 0.86, blue: 0.80)
    static let blue = Color(red: 0.16, green: 0.42, blue: 0.96)
    static let amber = Color(red: 0.95, green: 0.61, blue: 0.22)
    static let danger = Color(red: 0.90, green: 0.25, blue: 0.24)

    static let background = canvas
    static let panel = surface
    static let muted = secondaryInk
}

enum AppMotion {
    static let quick = Animation.easeOut(duration: 0.16)
    static let standard = Animation.easeInOut(duration: 0.28)
    static let spatial = Animation.spring(response: 0.46, dampingFraction: 0.84)
    static let settle = Animation.spring(response: 0.62, dampingFraction: 0.78)
}

@MainActor
enum AppHaptics {
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    static func impact() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred(intensity: 0.72)
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = AppTheme.blue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(tint.opacity(configuration.isPressed ? 0.76 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: tint.opacity(configuration.isPressed ? 0.10 : 0.24), radius: 16, y: 8)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(AppMotion.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppTheme.surface.opacity(configuration.isPressed ? 0.62 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.separator, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(AppMotion.quick, value: configuration.isPressed)
    }
}

struct CameraButtonStyle: ButtonStyle {
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(prominent ? Color.black.opacity(0.86) : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                prominent ? AppTheme.cyan.opacity(configuration.isPressed ? 0.76 : 1) : Color.white.opacity(configuration.isPressed ? 0.08 : 0.12),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                if !prominent {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.14), lineWidth: 1)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(AppMotion.quick, value: configuration.isPressed)
    }
}

struct StudioPage<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: 680)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 34)
                .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppTheme.canvas.ignoresSafeArea())
        .foregroundStyle(AppTheme.ink)
    }
}

struct StudioHeader: View {
    let eyebrow: LocalizedStringKey
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(.caption.weight(.bold))
                .tracking(1.25)
                .foregroundStyle(AppTheme.blue)
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
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
    let systemImage: String
    var tint = AppTheme.cyan

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(tint.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.20), lineWidth: 1))
    }
}

extension View {
    func appBackground() -> some View {
        background(AppTheme.canvas.ignoresSafeArea())
            .foregroundStyle(AppTheme.ink)
    }

    func studioSurface(padding: CGFloat = 18, radius: CGFloat = 24) -> some View {
        self
            .padding(padding)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(AppTheme.separator, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.055), radius: 22, y: 10)
    }

    func cameraSurface(padding: CGFloat = 18, radius: CGFloat = 24) -> some View {
        self
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .background(AppTheme.cameraPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
    }

    func glassPanel(padding: CGFloat = 18) -> some View {
        studioSurface(padding: padding)
    }
}
