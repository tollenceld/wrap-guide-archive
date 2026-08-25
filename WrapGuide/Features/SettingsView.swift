import AVFoundation
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("unitPreference") private var unitPreference = LengthUnitPreference.automatic.rawValue
    @AppStorage("voicePrompts") private var voicePrompts = false
    @State private var legalPage: LegalPage?

    var body: some View {
        NavigationStack {
            List {
                Section("settings.guidance") {
                    Picker("settings.units", selection: $unitPreference) {
                        Text("settings.units.auto").tag(LengthUnitPreference.automatic.rawValue)
                        Text("settings.units.metric").tag(LengthUnitPreference.metric.rawValue)
                        Text("settings.units.imperial").tag(LengthUnitPreference.imperial.rawValue)
                    }
                    Toggle("settings.voice", isOn: $voicePrompts)
                }
                .listRowBackground(AppTheme.surface)

                Section("settings.camera") {
                    HStack {
                        Label("settings.camera.status", systemImage: "camera")
                        Spacer()
                        Text(cameraStatus)
                            .foregroundStyle(AppTheme.muted)
                    }
                    Button("settings.openSettings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                .listRowBackground(AppTheme.surface)

                Section("settings.about") {
                    Button("settings.privacy") { legalPage = .privacy }
                    Button("settings.support") { legalPage = .support }
                    HStack {
                        Text("settings.version")
                        Spacer()
                        Text("1.0 (1)").foregroundStyle(AppTheme.muted)
                    }
                }
                .listRowBackground(AppTheme.surface)
            }
            .scrollContentBackground(.hidden)
            .appBackground()
            .navigationTitle("settings.title")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.done") { dismiss() }
                }
            }
            .sheet(item: $legalPage) { page in
                LegalTextView(page: page)
            }
        }
    }

    private var cameraStatus: LocalizedStringKey {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: "settings.camera.allowed"
        case .denied, .restricted: "settings.camera.denied"
        case .notDetermined: "settings.camera.notAsked"
        @unknown default: "settings.camera.denied"
        }
    }
}

enum LegalPage: String, Identifiable {
    case privacy
    case support
    var id: String { rawValue }
}

struct LegalTextView: View {
    @Environment(\.dismiss) private var dismiss
    let page: LegalPage

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(page == .privacy ? "legal.privacy.body" : "legal.support.body")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(22)
            }
            .appBackground()
            .navigationTitle(page == .privacy ? "settings.privacy" : "settings.support")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.done") { dismiss() }
                }
            }
        }
    }
}
