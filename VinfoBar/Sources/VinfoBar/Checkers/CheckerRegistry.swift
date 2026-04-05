import Foundation

final class CheckerRegistry {
    static let shared = CheckerRegistry()

    private var checkers: [String: any EnvironmentChecker.Type] = [:]

    private init() {
        // Register all checkers
        register(PythonChecker.self)
        register(NodeChecker.self)
        register(DockerChecker.self)
        register(GitChecker.self)
    }

    func register(_ checkerType: any EnvironmentChecker.Type) {
        checkers[checkerType.name] = checkerType
    }

    func getAllCheckers() -> [any EnvironmentChecker.Type] {
        checkers.values.sorted { $0.priority < $1.priority }
    }

    func getChecker(name: String) -> (any EnvironmentChecker.Type)? {
        checkers[name]
    }

    func getRegisteredNames() -> [String] {
        Array(checkers.keys)
    }
}