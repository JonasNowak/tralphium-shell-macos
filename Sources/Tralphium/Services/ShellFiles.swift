import Foundation

/// Where the shell keeps its files: `~/Library/Application Support/Tralphium`.
enum ShellFiles {
    static let directory: URL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Tralphium", isDirectory: true)

    static let config = directory.appendingPathComponent("config.json")
    static let pins = directory.appendingPathComponent("pins.json")
    static let hidden = directory.appendingPathComponent("hidden_apps.json")

    static func ensureDirectory() {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
