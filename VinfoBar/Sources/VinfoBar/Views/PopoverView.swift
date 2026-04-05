import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var service: EnvironmentService

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("VinfoBar")
                    .font(.headline)
                Spacer()
                HStack(spacing: 8) {
                    Button(action: { Task { await service.refresh() } }) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(service.isRefreshing ? 360 : 0))
                            .animation(
                                service.isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                value: service.isRefreshing
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(service.isRefreshing)

                    Button("Settings") {
                        NSApp.sendAction(#selector(AppDelegate.openSettings), to: nil, from: nil)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Content
            if service.isRefreshing && service.environments.isEmpty {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if service.environments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No environments detected")
                        .foregroundColor(.secondary)
                    Button("Refresh") {
                        Task { await service.refresh() }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView {
                    ForEach(service.environments, id: \.name) { env in
                        CheckerTabView(info: env)
                            .tabItem {
                                Label(env.displayName, systemImage: env.status.icon)
                            }
                    }
                }
                .tabViewStyle(.automatic)
            }

            Divider()

            // Footer
            HStack {
                if service.lastRefresh != .distantPast {
                    Text("Updated: \(service.lastRefresh, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .frame(width: 420, height: 450)
    }
}

struct CheckerTabView: View {
    let info: any EnvironmentInfo
    @EnvironmentObject var service: EnvironmentService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Content based on type
                if let pythonInfo = info as? PythonInfo {
                    PythonCheckerContent(info: pythonInfo)
                } else if let nodeInfo = info as? NodeInfo {
                    NodeCheckerContent(info: nodeInfo)
                } else if let dockerInfo = info as? DockerInfo {
                    DockerCheckerContent(info: dockerInfo)
                } else if let gitInfo = info as? GitInfo {
                    GitCheckerContent(info: gitInfo)
                } else {
                    GeneralCheckerContent(info: info)
                }
            }
            .padding()
        }
    }
}

// MARK: - Python Content (matches CLI: Overview + Virtual Environments + Actions)

struct PythonCheckerContent: View {
    let info: PythonInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Overview section
            CheckerSection(title: "Overview") {
                CheckerRow(label: "Version", value: info.version ?? "Unknown")
                CheckerRow(label: "Interpreter", value: info.interpreter ?? "CPython")
                CheckerRow(label: "Path", value: info.path ?? "N/A")
                CheckerRow(label: "Platform", value: info.platform ?? "N/A")
                CheckerRow(label: "Site-packages", value: info.sitePackagesPath ?? "N/A")
                CheckerRow(label: "Pyenv", value: info.pyenvInstalled ? "Yes" : "No")
                if info.pyenvInstalled {
                    CheckerRow(label: "Pyenv Global", value: info.pyenvCurrent ?? "N/A")
                    CheckerRow(label: "Pyenv Versions", value: "\(info.pyenvVersions.count) installed")
                }
            }

            // Virtual Environments section
            CheckerSection(title: "Virtual Environments") {
                if info.virtualenvs.isEmpty {
                    Text("No virtual environments found.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    VStack(spacing: 4) {
                        ForEach(info.virtualenvs) { venv in
                            HStack {
                                Text(venv.name)
                                    .font(.subheadline)
                                Text(venv.pythonVersion)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Spacer()
                                Text(venv.path)
                                    .foregroundStyle(.tertiary)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                }
            }

            // Actions section
            CheckerSection(title: "Actions") {
                VStack(alignment: .leading, spacing: 6) {
                    ActionRow(number: 1, description: "List all detected virtual environments", command: "list_venvs")
                    ActionRow(number: 2, description: "List installed pip packages", command: "list_pip")
                    ActionRow(number: 3, description: "Check for outdated pip packages", command: "pip_outdated")
                    ActionRow(number: 4, description: "Show site-packages directory", command: "site_packages")
                }
            }
        }
    }
}

// MARK: - Node Content (matches CLI: Overview + Actions)

struct NodeCheckerContent: View {
    let info: NodeInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Overview section
            CheckerSection(title: "Overview") {
                CheckerRow(label: "Version", value: info.version ?? "Unknown")
                CheckerRow(label: "Path", value: info.path ?? "N/A")
                CheckerRow(label: "npm Version", value: info.npmVersion ?? "N/A")
            }

            // Version Managers section
            if info.nvmInstalled || info.fnmInstalled || info.voltaInstalled {
                VersionManagersSection(info: info)
            }

            // Actions section
            CheckerSection(title: "Actions") {
                VStack(alignment: .leading, spacing: 6) {
                    ActionRow(number: 1, description: "List globally installed npm packages", command: "list_global")
                    ActionRow(number: 2, description: "Check for outdated global packages", command: "npm_outdated")
                    ActionRow(number: 3, description: "Show Node.js binary path", command: "node_path")
                    ActionRow(number: 4, description: "Show global npm modules directory", command: "npm_prefix")
                }
            }
        }
    }
}

struct VersionManagersSection: View {
    let info: NodeInfo

    var body: some View {
        CheckerSection(title: "Version Managers") {
            CheckerRow(label: "Installed", value: versionManagersText)
        }
    }

    private var versionManagersText: String {
        var managers: [String] = []
        if info.nvmInstalled {
            managers.append("nvm (current: \(info.nvmCurrent ?? "N/A"))")
        }
        if info.fnmInstalled {
            managers.append("fnm")
        }
        if info.voltaInstalled {
            managers.append("volta")
        }
        return managers.joined(separator: ", ")
    }
}

// MARK: - Docker Content (matches CLI: Overview + Containers + Images + Actions)

struct DockerCheckerContent: View {
    let info: DockerInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Overview section
            CheckerSection(title: "Overview") {
                CheckerRow(label: "Version", value: info.version ?? "Unknown")
                CheckerRow(label: "Daemon", value: info.daemonRunning ? "Running" : "Stopped")
                CheckerRow(label: "Context", value: info.contextName ?? "default")
                if let composeVersion = info.composeVersion {
                    CheckerRow(label: "Docker Compose", value: composeVersion)
                }
            }

            // Containers section
            CheckerSection(title: "Containers") {
                if info.containers.isEmpty {
                    Text("No containers found.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    VStack(spacing: 4) {
                        ForEach(info.containers) { container in
                            HStack {
                                Text(container.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Text(container.image)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Text(container.status)
                                    .foregroundColor(container.status.contains("running") ? .green : .secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }

            // Images section
            CheckerSection(title: "Images") {
                if info.images.isEmpty {
                    Text("No images found.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    VStack(spacing: 4) {
                        ForEach(info.images) { image in
                            HStack {
                                Text(image.repository)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Text(image.tag)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text(image.size)
                                    .foregroundStyle(.tertiary)
                                    .font(.caption2)
                                Spacer()
                            }
                        }
                    }
                }
            }

            // Actions section
            CheckerSection(title: "Actions") {
                VStack(alignment: .leading, spacing: 6) {
                    ActionRow(number: 1, description: "List all containers (running and stopped)", command: "list_containers")
                    ActionRow(number: 2, description: "List all Docker images", command: "list_images")
                    ActionRow(number: 3, description: "Show Docker disk usage breakdown", command: "disk_usage")
                    ActionRow(number: 4, description: "Remove all dangling images", command: "prune_images", dangerous: true)
                    ActionRow(number: 5, description: "Remove all unused volumes", command: "prune_volumes", dangerous: true)
                    ActionRow(number: 6, description: "Remove all unused containers, networks, and dangling images", command: "prune_all", dangerous: true)
                }
            }
        }
    }
}

// MARK: - Git Content (matches CLI: Identity + Repository + Actions)

struct GitCheckerContent: View {
    let info: GitInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Identity section
            CheckerSection(title: "Identity") {
                CheckerRow(label: "Version", value: info.version ?? "Unknown")
                CheckerRow(label: "Path", value: info.path ?? "N/A")
                CheckerRow(label: "User Name", value: info.userName ?? "Not configured", highlightMissing: info.userName == nil)
                CheckerRow(label: "User Email", value: info.userEmail ?? "Not configured", highlightMissing: info.userEmail == nil)
                CheckerRow(label: "Signing Key", value: info.signingKey ?? "None")
                CheckerRow(label: "Default Branch", value: info.defaultBranch ?? "main")
                CheckerRow(label: "GitHub CLI", value: info.ghInstalled ? "Installed" : "Not installed")
                if info.ghInstalled {
                    if let ghVersion = info.ghVersion {
                        CheckerRow(label: "gh Version", value: ghVersion)
                    }
                    CheckerRow(label: "gh Auth", value: info.ghAuthStatus ?? "N/A")
                    if let ghUser = info.ghUser {
                        CheckerRow(label: "gh User", value: ghUser)
                    }
                }
            }

            // Repository section
            CheckerSection(title: "Repository") {
                if info.currentRepo == nil {
                    Text("Not inside a git repository.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    CheckerRow(label: "Repository", value: info.currentRepo ?? "N/A")
                    CheckerRow(label: "Branch", value: info.currentBranch ?? "unknown")
                    if !info.remotes.isEmpty {
                        VStack(spacing: 4) {
                            ForEach(info.remotes) { remote in
                                HStack {
                                    Text(remote.name)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(remote.url)
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }

            // Actions section
            CheckerSection(title: "Actions") {
                VStack(alignment: .leading, spacing: 6) {
                    ActionRow(number: 1, description: "Show configured git user identity", command: "show_identity")
                    ActionRow(number: 2, description: "Open git global config in $EDITOR", command: "edit_config")
                    if info.ghInstalled {
                        ActionRow(number: 3, description: "Show GitHub CLI authentication status", command: "gh_status")
                        if info.ghAuthStatus != "logged_in" {
                            ActionRow(number: 4, description: "Run GitHub CLI authentication flow", command: "gh_auth")
                        }
                    }
                    ActionRow(number: 5, description: "Show current git branch", command: "current_branch")
                    ActionRow(number: 6, description: "List git remote repositories", command: "show_remotes")
                }
            }
        }
    }
}

// MARK: - General Content

struct GeneralCheckerContent: View {
    let info: any EnvironmentInfo

    var body: some View {
        CheckerSection(title: "Details") {
            CheckerRow(label: "Version", value: info.version ?? "Unknown")
            CheckerRow(label: "Path", value: info.path ?? "N/A")
            if !info.errors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Warnings")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    ForEach(info.errors, id: \.self) { error in
                        Text(error)
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
            }
        }
    }
}

// MARK: - Helper Components

struct CheckerSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            content()
        }
    }
}

struct CheckerRow: View {
    let label: String
    let value: String
    var highlightMissing: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(highlightMissing ? .orange : .primary)
        }
    }
}

struct ActionRow: View {
    let number: Int
    let description: String
    let command: String
    var dangerous: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text("\(number).")
                .font(.caption)
                .foregroundColor(.secondary)
            if dangerous {
                Text("!")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(description)
                    .font(.caption)
                Text(command)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}