import Foundation

final class ProviderRegistry {
    static let shared = ProviderRegistry()

    private var providers: [String: any EnvironmentProvider.Type] = [:]

    private init() {
        // Register all providers
        register(PythonProvider.self)
        register(NodeProvider.self)
        register(DockerProvider.self)
        register(GitProvider.self)
    }

    func register(_ providerType: any EnvironmentProvider.Type) {
        providers[providerType.name] = providerType
    }

    func getAllProviders() -> [any EnvironmentProvider.Type] {
        providers.values.sorted { $0.priority < $1.priority }
    }

    func getProvider(name: String) -> (any EnvironmentProvider.Type)? {
        providers[name]
    }

    func getRegisteredNames() -> [String] {
        Array(providers.keys)
    }
}