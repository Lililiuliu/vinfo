import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var configService: ConfigService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        TabView {
            GeneralSettingsView()
                .environmentObject(configService)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            ProviderSettingsView()
                .environmentObject(configService)
                .tabItem {
                    Label("Providers", systemImage: "list.bullet.rectangle")
                }
        }
        .frame(width: 480, height: 320)
        .padding()
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var configService: ConfigService

    var body: some View {
        Form {
            Section("Auto Refresh") {
                Picker("Refresh Frequency", selection: $configService.config.refreshInterval) {
                    ForEach(RefreshFrequency.allCases, id: \.self) { freq in
                        Text(freq.label).tag(freq)
                    }
                }
                .onChange(of: configService.config.refreshInterval) { _, newValue in
                    EnvironmentService.shared.setupAutoRefresh()
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Project")
                    Spacer()
                    Link("GitHub", destination: URL(string: "https://github.com")!)
                }
            }
        }
    }
}

struct ProviderSettingsView: View {
    @EnvironmentObject var configService: ConfigService

    var body: some View {
        Form {
            Section("Enabled Providers") {
                Toggle("Python", isOn: $configService.config.showPython)
                Toggle("Node.js", isOn: $configService.config.showNode)
                Toggle("Docker", isOn: $configService.config.showDocker)
                Toggle("Git", isOn: $configService.config.showGit)
            }

            Section("Warnings") {
                Toggle("Warn if Git identity not set", isOn: $configService.config.warnNoGitIdentity)
            }

            Section("Thresholds") {
                HStack {
                    Slider(value: Binding(
                        get: { Double(configService.config.diskWarningThreshold) },
                        set: { configService.config.diskWarningThreshold = Int($0) }
                    ), in: 50...100, step: 5)
                    Text("\(configService.config.diskWarningThreshold)%")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}