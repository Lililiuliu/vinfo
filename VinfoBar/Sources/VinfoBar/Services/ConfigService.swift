import Foundation
import Combine

final class ConfigService: ObservableObject {
    static let shared = ConfigService()

    private let defaults = UserDefaults.standard
    private let configKey = "vinfo AppConfig"

    @Published var config: AppConfig {
        didSet { save() }
    }

    private init() {
        if let data = defaults.data(forKey: configKey),
           let decoded = try? JSONDecoder().decode(AppConfig.self, from: data) {
            config = decoded
        } else {
            config = .default
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: configKey)
    }

    func reset() {
        config = .default
    }
}