import Foundation
import Combine

@MainActor
final class EnvironmentService: ObservableObject {
    static let shared = EnvironmentService()

    @Published var environments: [any EnvironmentInfo] = []
    @Published var isRefreshing = false
    @Published var lastRefresh: Date = .distantPast
    @Published var errorMessage: String?

    private let configService = ConfigService.shared
    private var refreshTimer: Timer?

    private init() {
        setupAutoRefresh()
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil

        let providers = ProviderRegistry.shared.getAllProviders()
        var results: [any EnvironmentInfo] = []

        await withTaskGroup(of: (any EnvironmentInfo)?.self) { group in
            for providerType in providers {
                // Filter by config
                let name = providerType.name
                if !shouldShowProvider(name: name) {
                    continue
                }

                group.addTask {
                    let provider = await self.createProvider(providerType)
                    let detected = await provider.detect()

                    if !detected {
                        return BaseEnvironmentInfo(
                            name: providerType.name,
                            displayName: providerType.displayName,
                            status: .notFound
                        )
                    }

                    var info = await provider.collect()
                    let (status, errors) = await provider.healthCheck()
                    if status != .unknown {
                        info.status = status
                    }
                    info.errors = errors
                    return info
                }
            }

            for await result in group {
                if let info = result {
                    results.append(info)
                }
            }
        }

        // Sort by priority
        environments = results.sorted { env1, env2 in
            let p1 = ProviderRegistry.shared.getProvider(name: env1.name)?.priority ?? 100
            let p2 = ProviderRegistry.shared.getProvider(name: env2.name)?.priority ?? 100
            return p1 < p2
        }

        isRefreshing = false
        lastRefresh = Date()
    }

    private func shouldShowProvider(name: String) -> Bool {
        switch name {
        case "python": return configService.config.showPython
        case "node": return configService.config.showNode
        case "docker": return configService.config.showDocker
        case "git": return configService.config.showGit
        default: return true
        }
    }

    private func createProvider(_ type: any EnvironmentProvider.Type) -> any EnvironmentProvider {
        // Providers are classes, so we instantiate them
        if type == PythonProvider.self {
            return PythonProvider()
        } else if type == NodeProvider.self {
            return NodeProvider()
        } else if type == DockerProvider.self {
            return DockerProvider()
        } else if type == GitProvider.self {
            return GitProvider()
        }
        // Fallback
        return PythonProvider()
    }

    func setupAutoRefresh() {
        refreshTimer?.invalidate()

        guard let interval = configService.config.refreshInterval.seconds else { return }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }

    func getProvider(for name: String) -> (any EnvironmentProvider.Type)? {
        return ProviderRegistry.shared.getProvider(name: name)
    }
}