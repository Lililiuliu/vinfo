import Foundation

actor CommandRunner {
    static let shared = CommandRunner()

    private let defaultTimeout: TimeInterval = 15

    private init() {}

    func run(
        _ command: String,
        timeout: TimeInterval? = nil,
        environment: [String: String]? = nil
    ) async -> CommandResult {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-c", command]

        // Set up pipes
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        task.standardOutput = stdoutPipe
        task.standardError = stderrPipe

        // Set environment if provided
        if let env = environment {
            var mergedEnv = ProcessInfo.processInfo.environment
            for (key, value) in env {
                mergedEnv[key] = value
            }
            task.environment = mergedEnv
        }

        do {
            try task.run()
        } catch {
            return CommandResult(
                success: false,
                stdout: "",
                stderr: "Failed to launch: \(error.localizedDescription)",
                returnCode: -1,
                command: command
            )
        }

        // Wait with timeout
        let timeoutSeconds = timeout ?? defaultTimeout
        let deadline = Date().addingTimeInterval(timeoutSeconds)

        while task.isRunning && Date() < deadline {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        if task.isRunning {
            task.terminate()
            return CommandResult(
                success: false,
                stdout: "",
                stderr: "Command timed out",
                returnCode: -1,
                command: command
            )
        }

        // Read output
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        return CommandResult(
            success: task.terminationStatus == 0,
            stdout: String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            stderr: String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            returnCode: task.terminationStatus,
            command: command
        )
    }

    func runMany(_ commands: [String]) async -> [CommandResult] {
        await withTaskGroup(of: CommandResult.self) { group in
            for cmd in commands {
                group.addTask { await self.run(cmd) }
            }
            var results: [CommandResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }

    nonisolated func which(_ name: String) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = [name]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {}
        return nil
    }
}