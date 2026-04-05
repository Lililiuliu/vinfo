import Foundation

struct VirtualEnv: Codable, Hashable, Identifiable {
    var id = UUID()
    let name: String
    let path: String
    let pythonVersion: String
}

struct PipPackage: Codable, Hashable, Identifiable {
    var id = UUID()
    let name: String
    let version: String
}

struct PythonInfo: EnvironmentInfo, Codable {
    var id = UUID()
    let name: String
    var displayName: String
    var status: HealthStatus = .unknown
    var version: String?
    var path: String?
    var errors: [String] = []
    var actionsAvailable: [String] = []

    // Python-specific fields
    var pyenvInstalled: Bool = false
    var pyenvVersions: [String] = []
    var pyenvCurrent: String?
    var virtualenvs: [VirtualEnv] = []
    var pipPackages: [PipPackage] = []
    var pipVersion: String?
    var sitePackagesPath: String?
    var interpreter: String?
    var platform: String?

    init(displayName: String = "Python") {
        self.name = "python"
        self.displayName = displayName
    }
}