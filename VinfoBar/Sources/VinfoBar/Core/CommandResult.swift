import Foundation

struct CommandResult {
    let success: Bool
    let stdout: String
    let stderr: String
    let returnCode: Int32
    let command: String
}