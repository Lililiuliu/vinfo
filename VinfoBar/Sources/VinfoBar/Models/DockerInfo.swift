import Foundation

struct DockerContainer: Codable, Hashable, Identifiable {
    var id = UUID()
    let containerId: String
    let name: String
    let image: String
    let status: String
}

struct DockerImage: Codable, Hashable, Identifiable {
    var id = UUID()
    let imageId: String
    let repository: String
    let tag: String
    let size: String
}

struct DockerVolume: Codable, Hashable, Identifiable {
    var id = UUID()
    let name: String
    let driver: String
}

struct DockerInfo: EnvironmentInfo, Codable {
    var id = UUID()
    let name: String
    var displayName: String
    var status: HealthStatus = .unknown
    var version: String?
    var path: String?
    var errors: [String] = []
    var actionsAvailable: [String] = []

    // Docker-specific fields
    var daemonRunning: Bool = false
    var containers: [DockerContainer] = []
    var images: [DockerImage] = []
    var volumes: [DockerVolume] = []
    var diskUsage: String?
    var composeVersion: String?
    var contextName: String?

    init(displayName: String = "Docker") {
        self.name = "docker"
        self.displayName = displayName
    }
}