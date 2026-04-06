import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var service: EnvironmentService
    @State private var selectedEnvironment: (any EnvironmentInfo)?
    @State private var showDetail = false

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
                            .font(.system(size: 12))
                            .rotationEffect(.degrees(service.isRefreshing ? 360 : 0))
                            .animation(
                                service.isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                value: service.isRefreshing
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(service.isRefreshing)

                    Button(action: { NSApp.sendAction(#selector(AppDelegate.openSettings), to: nil, from: nil) }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)

                    Button(action: { NSApp.terminate(nil) }) {
                        Image(systemName: "power")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Content
            if let env = selectedEnvironment, showDetail {
                CheckerDetailView(info: env, onBack: {
                    showDetail = false
                })
            } else if service.isRefreshing && service.environments.isEmpty {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if service.environments.isEmpty {
                EmptyStateView()
            } else {
                OverviewView(
                    environments: service.environments,
                    onSelectEnvironment: { env in
                        selectedEnvironment = env
                        showDetail = true
                    }
                )
            }

            Divider()

            // Footer
            HStack {
                if service.lastRefresh != .distantPast {
                    Text("Updated: \(service.lastRefresh, style: .relative)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Text("\(service.environments.count) environments")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: showDetail ? 400 : 360, height: showDetail ? 500 : 420)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("No environments detected")
                .foregroundStyle(.secondary)
            Button("Refresh") {
                Task { await EnvironmentService.shared.refresh() }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Overview (Dashboard)

struct OverviewView: View {
    let environments: [any EnvironmentInfo]
    let onSelectEnvironment: (any EnvironmentInfo) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(environments.enumerated()), id: \.element.name) { index, env in
                    EnvironmentRow(info: env) {
                        onSelectEnvironment(env)
                    }

                    if index < environments.count - 1 {
                        Divider()
                            .padding(.leading, 36)
                    }
                }
            }
        }
    }
}

// MARK: - Environment Row

struct EnvironmentRow: View {
    let info: any EnvironmentInfo
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(info.status.dotColor)
                    .frame(width: 8, height: 8)

                // Icon
                Image(systemName: iconForEnvironment(info.name))
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)

                    Text(quickDetails)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var quickDetails: String {
        switch info.name {
        case "python":
            let pInfo = info as? PythonInfo
            var parts: [String] = []
            if pInfo?.pyenvInstalled == true { parts.append("pyenv") }
            if let venvs = pInfo?.virtualenvs, !venvs.isEmpty { parts.append("\(venvs.count) venvs") }
            return parts.isEmpty ? "system" : parts.joined(separator: ", ")

        case "node":
            let nInfo = info as? NodeInfo
            var parts: [String] = []
            if nInfo?.nvmInstalled == true { parts.append("nvm") }
            else if nInfo?.fnmInstalled == true { parts.append("fnm") }
            else if nInfo?.voltaInstalled == true { parts.append("volta") }
            if let npm = nInfo?.npmVersion { parts.append("npm \(npm)") }
            return parts.isEmpty ? "system" : parts.joined(separator: ", ")

        case "docker":
            let dInfo = info as? DockerInfo
            var parts: [String] = []
            if dInfo?.daemonRunning == true { parts.append("running") }
            if let containers = dInfo?.containers { parts.append("\(containers.count) containers") }
            if let images = dInfo?.images { parts.append("\(images.count) images") }
            return parts.isEmpty ? "stopped" : parts.joined(separator: ", ")

        case "git":
            let gInfo = info as? GitInfo
            var parts: [String] = []
            if gInfo?.ghInstalled == true {
                parts.append("gh")
                if gInfo?.ghAuthStatus == "logged_in" { parts.append("authed") }
            }
            if let repo = gInfo?.currentRepo {
                parts.append("repo: \(URL(fileURLWithPath: repo).lastPathComponent)")
            }
            return parts.isEmpty ? "no repo" : parts.joined(separator: ", ")

        default:
            return info.version ?? "N/A"
        }
    }

    private func iconForEnvironment(_ name: String) -> String {
        switch name {
        case "python": return "chevron.left.forwardslash.chevron.right"
        case "node": return "square.fill"
        case "docker": return "cube.box"
        case "git": return "arrow.triangle.branch"
        default: return "questionmark.circle"
        }
    }
}

// MARK: - Checker Detail View

struct CheckerDetailView: View {
    let info: any EnvironmentInfo
    let onBack: () -> Void
    @EnvironmentObject var service: EnvironmentService

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.plain)

                Image(systemName: iconForEnvironment(info.name))
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(info.displayName)
                        .font(.headline)
                    if let version = info.version {
                        Text("v\(version)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                Circle()
                    .fill(info.status.dotColor)
                    .frame(width: 10, height: 10)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let pythonInfo = info as? PythonInfo {
                        PythonDetailContent(info: pythonInfo)
                    } else if let nodeInfo = info as? NodeInfo {
                        NodeDetailContent(info: nodeInfo)
                    } else if let dockerInfo = info as? DockerInfo {
                        DockerDetailContent(info: dockerInfo)
                    } else if let gitInfo = info as? GitInfo {
                        GitDetailContent(info: gitInfo)
                    } else {
                        GeneralDetailContent(info: info)
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 400, height: 500)
    }

    private func iconForEnvironment(_ name: String) -> String {
        switch name {
        case "python": return "chevron.left.forwardslash.chevron.right"
        case "node": return "square.fill"
        case "docker": return "cube.box"
        case "git": return "arrow.triangle.branch"
        default: return "questionmark.circle"
        }
    }
}

// MARK: - Python Detail

struct PythonDetailContent: View {
    let info: PythonInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailCard(title: "Overview") {
                DetailRow(label: "Version", value: info.version ?? "Unknown")
                DetailRow(label: "Interpreter", value: info.interpreter ?? "CPython")
                DetailCopyRow(label: "Path", value: info.path)
                DetailRow(label: "Platform", value: info.platform ?? "N/A")
                DetailCopyRow(label: "Site-packages", value: info.sitePackagesPath)

                if info.pyenvInstalled {
                    Divider()
                    DetailRow(label: "Pyenv", value: "Installed")
                    DetailRow(label: "Pyenv Global", value: info.pyenvCurrent ?? "N/A")
                    if !info.pyenvVersions.isEmpty {
                        DetailRow(label: "Pyenv Versions", value: "\(info.pyenvVersions.count) installed")
                    }
                }
            }

            DetailCard(title: "Virtual Environments", count: info.virtualenvs.count) {
                if info.virtualenvs.isEmpty {
                    Text("No virtual environments found")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(info.virtualenvs) { venv in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(venv.name)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text(venv.pythonVersion)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(venv.path)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 4)
                        if venv.id != info.virtualenvs.last?.id {
                            Divider()
                        }
                    }
                }
            }

            DetailCard(title: "Actions") {
                ActionList(actions: [
                    ActionItem(description: "List all virtual environments", command: "list_venvs"),
                    ActionItem(description: "List installed pip packages", command: "pip_list"),
                    ActionItem(description: "Check outdated packages", command: "pip_outdated"),
                    ActionItem(description: "Show site-packages path", command: "site_packages")
                ])
            }
        }
    }
}

// MARK: - Node Detail

struct NodeDetailContent: View {
    let info: NodeInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailCard(title: "Overview") {
                DetailRow(label: "Version", value: info.version ?? "Unknown")
                DetailCopyRow(label: "Path", value: info.path)
                DetailRow(label: "npm Version", value: info.npmVersion ?? "N/A")
            }

            if info.nvmInstalled || info.fnmInstalled || info.voltaInstalled {
                DetailCard(title: "Version Managers") {
                    if info.nvmInstalled {
                        DetailRow(label: "nvm", value: info.nvmCurrent ?? "installed")
                    }
                    if info.fnmInstalled {
                        DetailRow(label: "fnm", value: "installed")
                    }
                    if info.voltaInstalled {
                        DetailRow(label: "volta", value: "installed")
                    }
                }
            }

            DetailCard(title: "Actions") {
                ActionList(actions: [
                    ActionItem(description: "List global npm packages", command: "npm_list"),
                    ActionItem(description: "Check outdated packages", command: "npm_outdated"),
                    ActionItem(description: "Show Node path", command: "node_path"),
                    ActionItem(description: "Show npm prefix", command: "npm_prefix")
                ])
            }
        }
    }
}

// MARK: - Docker Detail

struct DockerDetailContent: View {
    let info: DockerInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailCard(title: "Overview") {
                DetailRow(label: "Version", value: info.version ?? "Unknown")
                HStack {
                    Text("Daemon")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .leading)
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(info.daemonRunning ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        Text(info.daemonRunning ? "Running" : "Stopped")
                            .font(.subheadline)
                    }
                }
                DetailRow(label: "Context", value: info.contextName ?? "default")
                if let compose = info.composeVersion {
                    DetailRow(label: "Compose", value: compose)
                }
            }

            DetailCard(title: "Containers", count: info.containers.count) {
                if info.containers.isEmpty {
                    Text("No containers")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    let running = info.containers.filter { $0.status.contains("running") }.count
                    VStack(alignment: .leading, spacing: 4) {
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(nsColor: .controlBackgroundColor))
                                if !info.containers.isEmpty {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.accentColor)
                                        .frame(width: geo.size.width * CGFloat(running) / CGFloat(info.containers.count))
                                }
                            }
                        }
                        .frame(height: 4)
                        Text("\(running)/\(info.containers.count) running")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    ForEach(info.containers.prefix(6)) { container in
                        HStack {
                            Circle()
                                .fill(container.status.contains("running") ? Color.green : Color.gray)
                                .frame(width: 6, height: 6)
                            Text(container.name)
                                .font(.caption)
                                .lineLimit(1)
                            Text(container.image)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                    if info.containers.count > 6 {
                        Text("+\(info.containers.count - 6) more")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            DetailCard(title: "Images", count: info.images.count) {
                if info.images.isEmpty {
                    Text("No images")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(info.images.prefix(6)) { image in
                        HStack {
                            Text(image.repository)
                                .font(.caption)
                                .lineLimit(1)
                            Text(":\(image.tag)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(image.size)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    if info.images.count > 6 {
                        Text("+\(info.images.count - 6) more")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            DetailCard(title: "Actions") {
                ActionList(actions: [
                    ActionItem(description: "List all containers", command: "docker_ps"),
                    ActionItem(description: "List all images", command: "docker_images"),
                    ActionItem(description: "Show disk usage", command: "docker_df"),
                    ActionItem(description: "Prune dangling images", command: "docker_prune_images", dangerous: true),
                    ActionItem(description: "Prune unused volumes", command: "docker_prune_volumes", dangerous: true)
                ])
            }
        }
    }
}

// MARK: - Git Detail

struct GitDetailContent: View {
    let info: GitInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailCard(title: "Identity") {
                DetailRow(label: "Version", value: info.version ?? "Unknown")
                DetailCopyRow(label: "Path", value: info.path)
                DetailRow(label: "User Name", value: info.userName ?? "Not configured", highlightMissing: info.userName == nil)
                DetailRow(label: "User Email", value: info.userEmail ?? "Not configured", highlightMissing: info.userEmail == nil)
                DetailRow(label: "Signing Key", value: info.signingKey ?? "None")
                DetailRow(label: "Default Branch", value: info.defaultBranch ?? "main")

                if info.ghInstalled {
                    Divider()
                    DetailRow(label: "GitHub CLI", value: "Installed")
                    if let ghVersion = info.ghVersion {
                        DetailRow(label: "gh Version", value: ghVersion)
                    }
                    HStack {
                        Text("gh Auth")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .leading)
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(info.ghAuthStatus == "logged_in" ? Color.green : Color.orange)
                                .frame(width: 6, height: 6)
                            Text(info.ghAuthStatus == "logged_in" ? "Logged In" : "Not Logged In")
                                .font(.subheadline)
                        }
                    }
                    if let ghUser = info.ghUser {
                        DetailRow(label: "gh User", value: ghUser)
                    }
                }
            }

            DetailCard(title: "Repository") {
                if info.currentRepo == nil {
                    Text("Not inside a git repository")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    DetailCopyRow(label: "Path", value: info.currentRepo)
                    DetailRow(label: "Branch", value: info.currentBranch ?? "unknown")

                    if !info.remotes.isEmpty {
                        Divider()
                        ForEach(info.remotes) { remote in
                            DetailCopyRow(label: remote.name, value: remote.url)
                        }
                    }
                }
            }

            DetailCard(title: "Actions") {
                var actions: [ActionItem] {
                    var items = [
                        ActionItem(description: "Show git identity", command: "git_identity"),
                        ActionItem(description: "Open git config", command: "git_config"),
                        ActionItem(description: "Show current branch", command: "git_branch"),
                        ActionItem(description: "List remotes", command: "git_remotes")
                    ]
                    if info.ghInstalled {
                        items.insert(ActionItem(description: "GitHub auth status", command: "gh_status"), at: 2)
                    }
                    return items
                }

                ActionList(actions: actions)
            }
        }
    }
}

// MARK: - General Detail

struct GeneralDetailContent: View {
    let info: any EnvironmentInfo

    var body: some View {
        DetailCard(title: "Details") {
            DetailRow(label: "Version", value: info.version ?? "Unknown")
            DetailCopyRow(label: "Path", value: info.path)

            if !info.errors.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Warnings")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    ForEach(info.errors, id: \.self) { error in
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Components

struct DetailCard<Content: View>: View {
    let title: String
    var count: Int? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let count = count {
                    Text("(\(count))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 0.5)
            )
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var highlightMissing: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(highlightMissing ? .orange : .primary)
        }
    }
}

struct DetailCopyRow: View {
    let label: String
    let value: String?
    @State private var copied = false

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Spacer()
            if let value = value, !value.isEmpty {
                Text(value)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation { copied = false }
                    }
                }) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundStyle(copied ? .green : .secondary)
                }
                .buttonStyle(.plain)
            } else {
                Text("N/A")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

struct ActionItem {
    let description: String
    let command: String
    var dangerous: Bool = false
}

struct ActionList: View {
    let actions: [ActionItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(actions, id: \.command) { action in
                HStack(spacing: 4) {
                    if action.dangerous {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                    }
                    Text(action.description)
                        .font(.caption)
                    Spacer()
                    Text(action.command)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

// MARK: - Health Status Extension

extension HealthStatus {
    var dotColor: Color {
        switch self {
        case .healthy: .green
        case .warning: .orange
        case .error: .red
        case .notFound: .gray
        case .unknown: .gray
        }
    }
}