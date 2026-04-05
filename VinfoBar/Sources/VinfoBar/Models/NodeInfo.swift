import Foundation

struct NodeInfo: EnvironmentInfo, Codable {
    var id = UUID()
    let name: String
    var displayName: String
    var status: HealthStatus = .unknown
    var version: String?
    var path: String?
    var errors: [String] = []
    var actionsAvailable: [String] = []

    // Node-specific fields
    var nvmInstalled: Bool = false
    var fnmInstalled: Bool = false
    var voltaInstalled: Bool = false
    var nvmVersions: [String] = []
    var nvmCurrent: String?
    var npmVersion: String?
    var globalPackages: [NpmPackage] = []

    init(displayName: String = "Node.js") {
        self.name = "node"
        self.displayName = displayName
    }
}

struct NpmPackage: Codable, Hashable, Identifiable {
    var id = UUID()
    let name: String
    let version: String
}