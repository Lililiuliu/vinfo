import Foundation

protocol EnvironmentInfo: Identifiable, Hashable {
    var id: UUID { get }
    var name: String { get }
    var displayName: String { get set }
    var status: HealthStatus { get set }
    var version: String? { get set }
    var path: String? { get set }
    var errors: [String] { get set }
    var actionsAvailable: [String] { get set }
}

struct BaseEnvironmentInfo: EnvironmentInfo, Codable {
    let id = UUID()
    let name: String
    var displayName: String
    var status: HealthStatus = .unknown
    var version: String?
    var path: String?
    var errors: [String] = []
    var actionsAvailable: [String] = []

    init(name: String, displayName: String, status: HealthStatus = .unknown) {
        self.name = name
        self.displayName = displayName
        self.status = status
    }
}