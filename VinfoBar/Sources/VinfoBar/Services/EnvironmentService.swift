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

        let checkers = CheckerRegistry.shared.getAllCheckers()
        var results: [any EnvironmentInfo] = []

        await withTaskGroup(of: (any EnvironmentInfo)?.self) { group in
            for checkerType in checkers {
                // Filter by config
                let name = checkerType.name
                if !shouldShowChecker(name: name) {
                    continue
                }

                group.addTask {
                    let checker = await self.createChecker(checkerType)
                    let detected = await checker.detect()

                    if !detected {
                        return BaseEnvironmentInfo(
                            name: checkerType.name,
                            displayName: checkerType.displayName,
                            status: .notFound
                        )
                    }

                    var info = await checker.collect()
                    let (status, errors) = await checker.healthCheck()
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
            let p1 = CheckerRegistry.shared.getChecker(name: env1.name)?.priority ?? 100
            let p2 = CheckerRegistry.shared.getChecker(name: env2.name)?.priority ?? 100
            return p1 < p2
        }

        isRefreshing = false
        lastRefresh = Date()
    }

    private func shouldShowChecker(name: String) -> Bool {
        switch name {
        case "python": return configService.config.showPython
        case "node": return configService.config.showNode
        case "docker": return configService.config.showDocker
        case "git": return configService.config.showGit
        default: return true
        }
    }

    private func createChecker(_ type: any EnvironmentChecker.Type) -> any EnvironmentChecker {
        // Checkers are classes, so we instantiate them
        if type == PythonChecker.self {
            return PythonChecker()
        } else if type == NodeChecker.self {
            return NodeChecker()
        } else if type == DockerChecker.self {
            return DockerChecker()
        } else if type == GitChecker.self {
            return GitChecker()
        }
        // Fallback
        return PythonChecker()
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

    func getChecker(for name: String) -> (any EnvironmentChecker.Type)? {
        return CheckerRegistry.shared.getChecker(name: name)
    }
}