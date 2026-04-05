import Foundation

final class DockerProvider: EnvironmentProvider {
    static let name = "docker"
    static let displayName = "Docker"
    static let icon = "docker"
    static let priority = 40

    private let runner = CommandRunner.shared

    func detect() async -> Bool {
        return runner.which("docker") != nil
    }

    func collect() async -> any EnvironmentInfo {
        // Version info
        let verResult = await runner.run("docker --version")

        var version = "Unknown"
        if verResult.success {
            // Extract version from "Docker version 24.0.5, build ..."
            let pattern = "Docker version ([0-9.]+)"
            if let range = verResult.stdout.range(of: pattern, options: .regularExpression) {
                version = verResult.stdout[range].replacingOccurrences(of: "Docker version ", with: "")
            }
        }

        var info = DockerInfo(displayName: "Docker \(version)")
        info.version = version
        info.path = runner.which("docker")

        // Check daemon (short timeout)
        let daemonResult = await runner.run("docker info --format '{{.ServerVersion}}' 2>/dev/null", timeout: 5)
        info.daemonRunning = daemonResult.success

        if info.daemonRunning {
            // Get containers, images, volumes in parallel
            async let containersResult = runner.run("docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}'")
            async let imagesResult = runner.run("docker images --format '{{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}'")
            async let volumesResult = runner.run("docker volume ls --format '{{.Name}}\t{{.Driver}}'")
            async let composeResult = runner.run("docker compose version --short 2>/dev/null || true")
            async let contextResult = runner.run("docker context show")

            let containers = await containersResult
            let images = await imagesResult
            let volumes = await volumesResult
            let compose = await composeResult
            let context = await contextResult

            // Parse containers
            if containers.success {
                info.containers = containers.stdout.split(separator: "\n").compactMap { line -> DockerContainer? in
                    let parts = line.split(separator: "\t", maxSplits: 3)
                    if parts.count >= 4 {
                        return DockerContainer(
                            containerId: String(parts[0]),
                            name: String(parts[1]),
                            image: String(parts[2]),
                            status: String(parts[3])
                        )
                    }
                    return nil
                }
            }

            // Parse images
            if images.success {
                info.images = images.stdout.split(separator: "\n").compactMap { line -> DockerImage? in
                    let parts = line.split(separator: "\t", maxSplits: 3)
                    if parts.count >= 4 {
                        return DockerImage(
                            imageId: String(parts[0]),
                            repository: String(parts[1]),
                            tag: String(parts[2]),
                            size: String(parts[3])
                        )
                    }
                    return nil
                }
            }

            // Parse volumes
            if volumes.success {
                info.volumes = volumes.stdout.split(separator: "\n").compactMap { line -> DockerVolume? in
                    let parts = line.split(separator: "\t")
                    if parts.count >= 2 {
                        return DockerVolume(name: String(parts[0]), driver: String(parts[1]))
                    }
                    return nil
                }
            }

            if compose.success && !compose.stdout.isEmpty {
                info.composeVersion = compose.stdout
            }

            if context.success {
                info.contextName = context.stdout
            }

            info.status = .healthy
        } else {
            info.status = .warning
            info.errors.append("Docker daemon not running")
        }

        return info
    }

    func healthCheck() async -> (HealthStatus, [String]) {
        if runner.which("docker") == nil {
            return (.notFound, ["Docker not installed"])
        }
        return (.healthy, [])
    }

    func quickActions() -> [ActionDefinition] {
        [
            ActionDefinition(id: "list_containers", label: "List Containers", description: "Show all containers", isDangerous: false),
            ActionDefinition(id: "list_images", label: "List Images", description: "Show all images", isDangerous: false),
            ActionDefinition(id: "prune_images", label: "Prune Images", description: "Remove dangling images", isDangerous: true),
        ]
    }
}