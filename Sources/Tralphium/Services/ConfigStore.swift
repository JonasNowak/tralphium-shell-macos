import Foundation
import Observation
import TralphiumCore

/// The loaded `config.json`. Edits made in the shell are saved to the file,
/// edits made to the file on disk are picked up immediately.
@MainActor
@Observable
final class ConfigStore {
    static let shared = ConfigStore()

    private(set) var config = TralphiumConfig()

    @ObservationIgnored private var lastData: Data?
    @ObservationIgnored private var source: DispatchSourceFileSystemObject?
    @ObservationIgnored private var observers: [@MainActor () -> Void] = []

    private init() {
        ShellFiles.ensureDirectory()
        if !FileManager.default.fileExists(atPath: ShellFiles.config.path) {
            // Write the defaults once so there is a file to edit.
            save()
        }
        reload()
        watch()
    }

    /// `handler` runs after every change, whether it came from the shell or the file.
    func observe(_ handler: @escaping @MainActor () -> Void) {
        observers.append(handler)
    }

    func update(_ change: (inout TralphiumConfig) -> Void) {
        var updated = config
        change(&updated)
        guard updated != config else { return }
        config = updated
        save()
        observers.forEach { $0() }
    }

    func reload() {
        let data = try? Data(contentsOf: ShellFiles.config)
        guard data != lastData else { return }
        lastData = data
        let loaded = TralphiumConfig(json: data)
        guard loaded != config else { return }
        config = loaded
        observers.forEach { $0() }
    }

    private func save() {
        let data = config.encoded(merging: lastData)
        lastData = data
        try? data.write(to: ShellFiles.config, options: .atomic)
    }

    /// Watches the file itself. Editors that save by replacing the file
    /// (rename or delete) end the watch, so it is re-armed afterwards.
    private func watch() {
        source?.cancel()
        let fd = open(ShellFiles.config.path, O_EVTONLY)
        guard fd >= 0 else { return }
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .extend, .delete, .rename], queue: .main)
        src.setEventHandler { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                let replaced = src.data.contains(.delete) || src.data.contains(.rename)
                if replaced {
                    // The new file appears a moment after the old one went away.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                        MainActor.assumeIsolated {
                            self?.reload()
                            self?.watch()
                        }
                    }
                } else {
                    self.reload()
                }
            }
        }
        src.setCancelHandler { close(fd) }
        src.resume()
        source = src
    }
}
