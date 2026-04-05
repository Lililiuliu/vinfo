import Foundation

struct AppConfig: Codable {
    var refreshInterval: RefreshFrequency = .off
    var showPython: Bool = true
    var showNode: Bool = true
    var showDocker: Bool = true
    var showGit: Bool = true
    var pythonPath: String = ""
    var nodePath: String = ""
    var dockerHost: String = ""
    var diskWarningThreshold: Int = 80
    var warnNoGitIdentity: Bool = true

    static let `default` = AppConfig()
}