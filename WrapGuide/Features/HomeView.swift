import SwiftUI

struct HomeView: View {
    let coordinator: AppCoordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        StudioPage {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 9) {
                        WrapMark()
                            .frame(width: 38, height: 38)
                        Text("home.title")
                            .font(.headline.weight(.bold))
                    }

                    Text("home.hero.title")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .tracking(-1.2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("home.subtitle")
                        .font(.title3)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                WrappingHeroView()
                    .frame(height: 274)
                    .padding(.top, 22)
                    .scaleEffect(appeared ? 1 : 0.96)
                    .opacity(appeared ? 1 : 0)

                VStack(spacing: 12) {
                    Button {
                        AppHaptics.impact()
                        Task { await coordinator.beginNewWrap() }
                    } label: {
                        Label("home.start", systemImage: "viewfinder")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("startWrapButton")

                    Button("home.manual") {
                        coordinator.useManualMeasurement()
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Label("home.privacy", systemImage: "lock.shield")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .padding(.top, 2)
                }
                .padding(.top, 18)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : AppMotion.settle) {
                appeared = true
            }
        }
    }
}

struct WrapMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.cyan, AppTheme.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "shippingbox")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: AppTheme.blue.opacity(0.20), radius: 12, y: 6)
        .accessibilityHidden(true)
    }
}
