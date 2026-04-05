import Foundation

final class GitChecker: EnvironmentChecker {
    static let name = "git"
    static let displayName = "Git"
    static let icon = "git"
    static let priority = 30

    private let runner = CommandRunner.shared

    func detect() async -> Bool {
        return runner.which("git") != nil
    }

    func collect() async -> any EnvironmentInfo {
        // Git config in parallel
        async let verResult = runner.run("git --version")
        async let nameResult = runner.run("git config --global user.name 2>/dev/null || true")
        async let emailResult = runner.run("git config --global user.email 2>/dev/null || true")
        async let signingResult = runner.run("git config --global user.signingkey 2>/dev/null || true")
        async let branchResult = runner.run("git config --global init.defaultBranch 2>/dev/null || true")

        let ver = await verResult
        let name = await nameResult
        let email = await emailResult
        let signing = await signingResult
        let branch = await branchResult

        var version = "Unknown"
        if ver.success {
            version = ver.stdout.replacingOccurrences(of: "git version ", with: "")
        }

        var info = GitInfo(displayName: "Git \(version)")
        info.version = version
        info.path = runner.which("git")
        info.status = .healthy

        if name.success && !name.stdout.isEmpty {
            info.userName = name.stdout
        }
        if email.success && !email.stdout.isEmpty {
            info.userEmail = email.stdout
        }
        if signing.success && !signing.stdout.isEmpty {
            info.signingKey = signing.stdout
        }
        if branch.success && !branch.stdout.isEmpty {
            info.defaultBranch = branch.stdout
        }

        // Check GitHub CLI
        if runner.which("gh") != nil {
            info.ghInstalled = true

            async let ghVerResult = runner.run("gh --version")
            async let ghAuthResult = runner.run("gh auth status 2>&1")

            let ghVer = await ghVerResult
            let ghAuth = await ghAuthResult

            if ghVer.success {
                // Extract version from first line
                let firstLine = ghVer.stdout.split(separator: "\n").first ?? ""
                info.ghVersion = firstLine.replacingOccurrences(of: "gh version ", with: "")
            }

            // Parse auth status
            if ghAuth.stdout.contains("Logged in") {
                info.ghAuthStatus = "logged_in"
                // Extract username from "account xxx"
                if let match = ghAuth.stdout.range(of: "account\\s+([^\\s\\(]+)", options: .regularExpression) {
                    info.ghUser = ghAuth.stdout[match].replacingOccurrences(of: "account ", with: "")
                }
            } else if ghAuth.stdout.contains("not logged in") {
                info.ghAuthStatus = "not_logged_in"
            }
        }

        // Check current repo
        let inRepoResult = await runner.run("git rev-parse --is-inside-work-tree 2>/dev/null || true")
        if inRepoResult.success && inRepoResult.stdout == "true" {
            async let repoRootResult = runner.run("git rev-parse --show-toplevel")
            async let currentBranchResult = runner.run("git branch --show-current")
            async let remotesResult = runner.run("git remote -v")

            let repoRoot = await repoRootResult
            let currentBranch = await currentBranchResult
            let remotes = await remotesResult

            if repoRoot.success {
                info.currentRepo = repoRoot.stdout
            }
            if currentBranch.success {
                info.currentBranch = currentBranch.stdout
            }

            // Parse remotes
            if remotes.success {
                var seenRemotes: Set<String> = []
                for line in remotes.stdout.split(separator: "\n") {
                    let parts = line.split(separator: "\t")
                    if parts.count >= 2 {
                        let remoteName = String(parts[0])
                        if !seenRemotes.contains(remoteName) {
                            seenRemotes.insert(remoteName)
                            let urlParts = parts[1].split(separator: " ")
                            info.remotes.append(GitRemote(name: remoteName, url: String(urlParts.first ?? "")))
                        }
                    }
                }
            }
        }

        return info
    }

    func healthCheck() async -> (HealthStatus, [String]) {
        var messages: [String] = []
        var status = HealthStatus.healthy

        if runner.which("git") == nil {
            return (.notFound, ["Git not installed"])
        }

        // Check if user identity is configured
        let nameResult = await runner.run("git config --global user.name 2>/dev/null || true")
        let emailResult = await runner.run("git config --global user.email 2>/dev/null || true")

        if !nameResult.success || nameResult.stdout.isEmpty {
            status = .warning
            messages.append("Git user.name not configured")
        }
        if !emailResult.success || emailResult.stdout.isEmpty {
            status = .warning
            messages.append("Git user.email not configured")
        }

        return (status, messages)
    }

    func quickActions() -> [ActionDefinition] {
        [
            ActionDefinition(id: "edit_config", label: "Edit Git Config", description: "Open git config in editor", isDangerous: false),
            ActionDefinition(id: "gh_login", label: "GitHub Login", description: "Login to GitHub CLI", isDangerous: false),
        ]
    }
}