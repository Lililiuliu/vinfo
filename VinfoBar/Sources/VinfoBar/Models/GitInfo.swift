import Foundation

struct GitRemote: Codable, Hashable, Identifiable {
    var id = UUID()
    let name: String
    let url: String
}

struct GitInfo: EnvironmentInfo, Codable {
    var id = UUID()
    let name: String
    var displayName: String
    var status: HealthStatus = .unknown
    var version: String?
    var path: String?
    var errors: [String] = []
    var actionsAvailable: [String] = []

    // Git-specific fields
    var userName: String?
    var userEmail: String?
    var signingKey: String?
    var defaultBranch: String?
    var ghInstalled: Bool = false
    var ghVersion: String?
    var ghAuthStatus: String?
    var ghUser: String?
    var currentRepo: String?
    var currentBranch: String?
    var remotes: [GitRemote] = []

    init(displayName: String = "Git") {
        self.name = "git"
        self.displayName = displayName
    }
}