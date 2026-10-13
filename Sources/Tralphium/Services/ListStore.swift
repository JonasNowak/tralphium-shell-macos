import Foundation
import Observation
import TralphiumCore

/// A persisted `IDList` (pinned apps, hidden apps).
@MainActor
@Observable
final class ListStore {
    static let pins = ListStore(url: ShellFiles.pins, defaultIDs: ["com.apple.finder", "com.apple.Safari", "com.apple.Terminal"])
    static let hidden = ListStore(url: ShellFiles.hidden)

    private(set) var list: IDList
    @ObservationIgnored private let url: URL

    private init(url: URL, defaultIDs: [String] = []) {
        self.url = url
        if let data = try? Data(contentsOf: url) {
            list = IDList(json: data)
        } else {
            list = IDList(defaultIDs)
        }
    }

    func contains(_ id: String) -> Bool { list.contains(id) }

    func toggle(_ id: String) { change { $0.toggle(id) } }

    func insert(_ id: String, at position: Int) { change { $0.insert(id, at: position) } }

    private func change(_ edit: (inout IDList) -> Void) {
        var updated = list
        edit(&updated)
        guard updated != list else { return }
        list = updated
        ShellFiles.ensureDirectory()
        try? updated.jsonData().write(to: url, options: .atomic)
    }
}
