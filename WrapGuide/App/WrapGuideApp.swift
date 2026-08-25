import Foundation
import SwiftData
import SwiftUI

@main
struct WrapGuideApp: App {
    private let modelContainer: ModelContainer = {
        let schema = Schema([PersistedSession.self])
        let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isTesting)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create Wrap Guide data store: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppFlowView()
        }
        .modelContainer(modelContainer)
    }
}
