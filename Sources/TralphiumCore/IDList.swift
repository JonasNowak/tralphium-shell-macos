import Foundation

/// Ordered list of ids without duplicates. Ids compare case-insensitively
/// but keep the case they were added with. Used for pinned and hidden apps,
/// persisted as a JSON array of strings.
public struct IDList: Equatable, Sendable {
    public private(set) var ids: [String]

    public init(_ ids: [String] = []) {
        self.ids = []
        for id in ids where !contains(id) && !id.isEmpty { self.ids.append(id) }
    }

    public init(json: Data?) {
        let strings = json.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [Any] ?? []
        self.init(strings.compactMap { $0 as? String })
    }

    public func jsonData() -> Data {
        (try? JSONSerialization.data(withJSONObject: ids, options: [.prettyPrinted])) ?? Data()
    }

    public func index(of id: String) -> Int? {
        ids.firstIndex { $0.caseInsensitiveCompare(id) == .orderedSame }
    }

    public func contains(_ id: String) -> Bool { index(of: id) != nil }

    public mutating func toggle(_ id: String) {
        guard !id.isEmpty else { return }
        if let i = index(of: id) { ids.remove(at: i) } else { ids.append(id) }
    }

    /// Inserts `id` at `position`, or moves it there when it is already in the list.
    public mutating func insert(_ id: String, at position: Int) {
        guard !id.isEmpty else { return }
        if let existing = index(of: id) {
            move(from: existing, to: position)
        } else {
            ids.insert(id, at: min(max(position, 0), ids.count))
        }
    }

    public mutating func move(from: Int, to: Int) {
        guard from != to, ids.indices.contains(from), ids.indices.contains(to) else { return }
        ids.insert(ids.remove(at: from), at: to)
    }
}
