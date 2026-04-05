import Foundation

struct ActionDefinition: Identifiable {
    let id: String
    let label: String
    let description: String
    let isDangerous: Bool
}

protocol EnvironmentProvider: AnyObject {
    static var name: String { get }
    static var displayName: String { get }
    static var icon: String { get }
    static var priority: Int { get }

    /// Check if the environment tool is installed
    func detect() async -> Bool

    /// Collect environment information
    func collect() async -> any EnvironmentInfo

    /// Perform health check
    func healthCheck() async -> (HealthStatus, [String])

    /// Get available quick actions
    func quickActions() -> [ActionDefinition]
}

extension EnvironmentProvider {
    static var priority: Int { 100 }
    func quickActions() -> [ActionDefinition] { [] }
}