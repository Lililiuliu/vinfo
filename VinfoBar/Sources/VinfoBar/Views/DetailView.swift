import SwiftUI

struct DetailView: View {
    let info: any EnvironmentInfo
    @EnvironmentObject var service: EnvironmentService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: info.status.icon)
                    .foregroundColor(info.status.color)
                    .font(.title)

                VStack(alignment: .leading, spacing: 2) {
                    Text(info.displayName)
                        .font(.title2)
                    if let version = info.version {
                        Text("Version: \(version)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button("Close") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            // Content based on type
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
                .padding()
            }

            Divider()

            // Footer with actions
            HStack {
                Button("Refresh") {
                    Task { await service.refresh() }
                }
                Spacer()
                if let path = info.path {
                    Button("Open in Terminal") {
                        openInTerminal(path: path)
                    }
                }
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }

    private func openInTerminal(path: String) {
        let script = "tell application \"Terminal\" to do script \"cd '\(path)'\""
        if let scriptURL = URL(string: "applecript://com.apple.scripteditor?action=new&script=\(script.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            NSWorkspace.shared.open(scriptURL)
        }
    }
}

// MARK: - Detail Contents

struct PythonDetailContent: View {
    let info: PythonInfo

    var body: some View {
        Group {
            InfoSection(title: "Installation") {
                if let path = info.path {
                    InfoRow(label: "Path", value: path)
                }
                if let interpreter = info.interpreter {
                    InfoRow(label: "Interpreter", value: interpreter)
                }
                if let pipVersion = info.pipVersion {
                    InfoRow(label: "pip", value: pipVersion)
                }
            }

            if info.pyenvInstalled {
                InfoSection(title: "pyenv") {
                    InfoRow(label: "Installed", value: "Yes")
                    if let current = info.pyenvCurrent {
                        InfoRow(label: "Current", value: current)
                    }
                    if !info.pyenvVersions.isEmpty {
                        InfoRow(label: "Versions", value: info.pyenvVersions.joined(separator: ", "))
                    }
                }
            }

            if !info.virtualenvs.isEmpty {
                InfoSection(title: "Virtual Environments (\(info.virtualenvs.count))") {
                    ForEach(info.virtualenvs) { venv in
                        HStack {
                            Text(venv.name)
                            Spacer()
                            Text(venv.pythonVersion)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct NodeDetailContent: View {
    let info: NodeInfo

    var body: some View {
        Group {
            InfoSection(title: "Installation") {
                if let path = info.path {
                    InfoRow(label: "Path", value: path)
                }
                if let npmVersion = info.npmVersion {
                    InfoRow(label: "npm", value: npmVersion)
                }
            }

            if info.nvmInstalled || info.fnmInstalled || info.voltaInstalled {
                InfoSection(title: "Version Managers") {
                    if info.nvmInstalled { InfoRow(label: "nvm", value: "Yes") }
                    if info.fnmInstalled { InfoRow(label: "fnm", value: "Yes") }
                    if info.voltaInstalled { InfoRow(label: "volta", value: "Yes") }
                    if let current = info.nvmCurrent {
                        InfoRow(label: "Current", value: current)
                    }
                    if !info.nvmVersions.isEmpty {
                        InfoRow(label: "Versions", value: info.nvmVersions.joined(separator: ", "))
                    }
                }
            }
        }
    }
}

struct DockerDetailContent: View {
    let info: DockerInfo

    var body: some View {
        Group {
            InfoSection(title: "Status") {
                InfoRow(label: "Daemon", value: info.daemonRunning ? "Running" : "Stopped")
                if let composeVersion = info.composeVersion {
                    InfoRow(label: "Compose", value: composeVersion)
                }
                if let context = info.contextName {
                    InfoRow(label: "Context", value: context)
                }
            }

            if !info.containers.isEmpty {
                InfoSection(title: "Containers (\(info.containers.count))") {
                    ForEach(info.containers) { container in
                        HStack {
                            Text(container.name)
                            Spacer()
                            Text(container.status)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if !info.images.isEmpty {
                InfoSection(title: "Images (\(info.images.count))") {
                    ForEach(info.images) { image in
                        HStack {
                            Text("\(image.repository):\(image.tag)")
                            Spacer()
                            Text(image.size)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct GitDetailContent: View {
    let info: GitInfo

    var body: some View {
        Group {
            InfoSection(title: "Identity") {
                if let name = info.userName {
                    InfoRow(label: "Name", value: name)
                }
                if let email = info.userEmail {
                    InfoRow(label: "Email", value: email)
                }
                if let signing = info.signingKey {
                    InfoRow(label: "Signing Key", value: signing)
                }
                if let branch = info.defaultBranch {
                    InfoRow(label: "Default Branch", value: branch)
                }
            }

            if info.ghInstalled {
                InfoSection(title: "GitHub CLI") {
                    if let version = info.ghVersion {
                        InfoRow(label: "Version", value: version)
                    }
                    if let status = info.ghAuthStatus {
                        InfoRow(label: "Auth Status", value: status == "logged_in" ? "Logged In" : "Not Logged In")
                    }
                    if let user = info.ghUser {
                        InfoRow(label: "User", value: user)
                    }
                }
            }

            if info.currentRepo != nil {
                InfoSection(title: "Current Repository") {
                    if let repo = info.currentRepo {
                        InfoRow(label: "Path", value: repo)
                    }
                    if let branch = info.currentBranch {
                        InfoRow(label: "Branch", value: branch)
                    }
                    if !info.remotes.isEmpty {
                        ForEach(info.remotes) { remote in
                            InfoRow(label: remote.name, value: remote.url)
                        }
                    }
                }
            }
        }
    }
}

struct GeneralDetailContent: View {
    let info: any EnvironmentInfo

    var body: some View {
        InfoSection(title: "Details") {
            if let path = info.path {
                InfoRow(label: "Path", value: path)
            }
            if let version = info.version {
                InfoRow(label: "Version", value: version)
            }
            if !info.errors.isEmpty {
                ForEach(info.errors, id: \.self) { error in
                    Text(error).foregroundColor(.orange)
                }
            }
        }
    }
}

// MARK: - Helper Components

struct InfoSection<Content: View>: View {
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

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}