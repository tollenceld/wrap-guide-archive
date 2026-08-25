import Foundation
import SwiftData

@Model
final class PersistedSession {
    @Attribute(.unique) var key: String
    @Attribute(.externalStorage) var payload: Data
    var updatedAt: Date

    init(key: String = "active", payload: Data, updatedAt: Date = .now) {
        self.key = key
        self.payload = payload
        self.updatedAt = updatedAt
    }
}

@MainActor
protocol SessionRepository: AnyObject {
    func loadActive() throws -> WrapSession?
    func save(_ session: WrapSession) throws
    func clear() throws
}

@MainActor
final class SwiftDataSessionRepository: SessionRepository {
    private let context: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(context: ModelContext) {
        self.context = context
    }

    func loadActive() throws -> WrapSession? {
        var descriptor = FetchDescriptor<PersistedSession>(predicate: #Predicate { $0.key == "active" })
        descriptor.fetchLimit = 1
        guard let stored = try context.fetch(descriptor).first else { return nil }
        return try decoder.decode(WrapSession.self, from: stored.payload)
    }

    func save(_ session: WrapSession) throws {
        let data = try encoder.encode(session)
        var descriptor = FetchDescriptor<PersistedSession>(predicate: #Predicate { $0.key == "active" })
        descriptor.fetchLimit = 1
        if let stored = try context.fetch(descriptor).first {
            stored.payload = data
            stored.updatedAt = .now
        } else {
            context.insert(PersistedSession(payload: data))
        }
        try context.save()
    }

    func clear() throws {
        try context.delete(model: PersistedSession.self)
        try context.save()
    }
}

