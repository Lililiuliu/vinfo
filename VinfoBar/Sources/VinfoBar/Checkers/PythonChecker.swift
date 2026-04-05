import Foundation

final class PythonChecker: EnvironmentChecker {
    static let name = "python"
    static let displayName = "Python"
    static let icon = "snake"
    static let priority = 10

    private let runner = CommandRunner.shared

    func detect() async -> Bool {
        return runner.which("python3") != nil || runner.which("python") != nil
    }

    func collect() async -> any EnvironmentInfo {
        let pythonBin = runner.which("python3") ?? runner.which("python") ?? ""

        // Parallel command execution
        async let verResult = runner.run("\(pythonBin) --version 2>&1")
        async let platResult = runner.run("\(pythonBin) -c 'import platform; print(platform.platform())'")
        async let siteResult = runner.run("\(pythonBin) -c 'import site; print(site.getsitepackages()[0] if site.getsitepackages() else site.getusersitepackages())'")
        async let pipResult = runner.run("\(pythonBin) -m pip --version 2>&1")

        let ver = await verResult
        let plat = await platResult
        let site = await siteResult
        let pip = await pipResult

        var version = "Unknown"
        if ver.success {
            version = ver.stdout.replacingOccurrences(of: "Python ", with: "").trimmingCharacters(in: .whitespaces)
        }

        var info = PythonInfo(displayName: "Python \(version)")
        info.version = version
        info.path = pythonBin
        info.status = .healthy
        info.interpreter = "CPython"
        info.platform = plat.success ? plat.stdout : nil
        info.sitePackagesPath = site.success ? site.stdout : nil

        if pip.success {
            let parts = pip.stdout.split(separator: " ")
            if parts.count > 1 {
                info.pipVersion = String(parts[1])
            }
        }

        // Check pyenv
        if runner.which("pyenv") != nil {
            info.pyenvInstalled = true
            async let versionsResult = runner.run("pyenv versions --bare")
            async let currentResult = runner.run("pyenv global 2>/dev/null || pyenv version-name 2>/dev/null || true")

            let versions = await versionsResult
            let current = await currentResult

            if versions.success {
                info.pyenvVersions = versions.stdout.components(separatedBy: "\n").filter { !$0.isEmpty }
            }
            if current.success && !current.stdout.isEmpty {
                info.pyenvCurrent = current.stdout
            }
        }

        // Find virtualenvs
        info.virtualenvs = await findVirtualEnvs()

        return info
    }

    private func findVirtualEnvs() async -> [VirtualEnv] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let searchPaths = [
            "\(home)/virtualenvs",
            "\(home)/.local/share/virtualenvs"
        ]

        var candidates: [(name: String, path: String)] = []

        for basePath in searchPaths {
            guard FileManager.default.fileExists(atPath: basePath) else { continue }
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: basePath)
                for name in contents {
                    let vpath = "\(basePath)/\(name)"
                    let pythonPath = "\(vpath)/bin/python"
                    if FileManager.default.fileExists(atPath: pythonPath) {
                        candidates.append((name, vpath))
                    }
                }
            } catch {}
        }

        // Check cwd .venv
        let cwdVenv = "\(FileManager.default.currentDirectoryPath)/.venv"
        if FileManager.default.fileExists(atPath: "\(cwdVenv)/bin/python") {
            candidates.append((".venv (cwd)", cwdVenv))
        }

        // Get versions in parallel
        var venvs: [VirtualEnv] = []
        for candidate in candidates {
            let result = await runner.run("\(candidate.path)/bin/python --version 2>&1")
            let pyVer = result.success ? result.stdout.replacingOccurrences(of: "Python ", with: "") : "unknown"
            venvs.append(VirtualEnv(name: candidate.name, path: candidate.path, pythonVersion: pyVer))
        }

        return venvs
    }

    func healthCheck() async -> (HealthStatus, [String]) {
        var messages: [String] = []
        var status = HealthStatus.healthy

        if runner.which("pip") == nil && runner.which("pip3") == nil {
            status = .warning
            messages.append("pip not found in PATH")
        }

        return (status, messages)
    }

    func quickActions() -> [ActionDefinition] {
        [
            ActionDefinition(id: "list_venvs", label: "List VirtualEnvs", description: "Show all detected virtual environments", isDangerous: false),
            ActionDefinition(id: "pip_packages", label: "List pip packages", description: "Show top installed pip packages", isDangerous: false),
        ]
    }
}