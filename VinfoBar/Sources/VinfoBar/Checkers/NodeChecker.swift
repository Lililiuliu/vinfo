import Foundation

final class NodeChecker: EnvironmentChecker {
    static let name = "node"
    static let displayName = "Node.js"
    static let icon = "nodejs"
    static let priority = 20

    private let runner = CommandRunner.shared

    func detect() async -> Bool {
        return runner.which("node") != nil
    }

    func collect() async -> any EnvironmentInfo {
        // Parallel command execution
        async let verResult = runner.run("node --version")
        async let npmResult = runner.run("npm --version 2>/dev/null || true")
        async let fnmCheck = runner.run("which fnm")
        async let voltaCheck = runner.run("which volta")

        let ver = await verResult
        let npm = await npmResult
        let fnm = await fnmCheck
        let volta = await voltaCheck

        var version = "Unknown"
        if ver.success {
            version = ver.stdout.replacingOccurrences(of: "v", with: "")
        }

        var info = NodeInfo(displayName: "Node.js \(version)")
        info.version = version
        info.path = runner.which("node")
        info.status = .healthy

        if npm.success && !npm.stdout.isEmpty {
            info.npmVersion = npm.stdout
        }

        info.fnmInstalled = fnm.success
        info.voltaInstalled = volta.success

        // Check nvm by directory existence
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let nvmDir = ProcessInfo.processInfo.environment["NVM_DIR"] ?? "\(home)/.nvm"
        let nvmVersionsDir = "\(nvmDir)/versions/node"

        if FileManager.default.fileExists(atPath: nvmVersionsDir) {
            info.nvmInstalled = true
            do {
                let versions = try FileManager.default.contentsOfDirectory(atPath: nvmVersionsDir)
                info.nvmVersions = versions.filter { !$0.isEmpty }

                // Get current version from nvm
                let currentResult = await runner.run("nvm current 2>/dev/null || true")
                if currentResult.success && !currentResult.stdout.isEmpty {
                    info.nvmCurrent = currentResult.stdout
                }
            } catch {}
        }

        return info
    }

    func healthCheck() async -> (HealthStatus, [String]) {
        return (.healthy, [])
    }

    func quickActions() -> [ActionDefinition] {
        [
            ActionDefinition(id: "npm_global", label: "List global packages", description: "Show npm global packages", isDangerous: false),
        ]
    }
}