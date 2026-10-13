import Foundation

/// An installed application.
public struct AppEntry: Identifiable, Equatable, Sendable {
    /// Bundle identifier.
    public let id: String
    public let name: String
    public let path: String

    public init(id: String, name: String, path: String) {
        self.id = id
        self.name = name
        self.path = path
    }
}

public enum AppSearch {
    /// Apps for the launchpad grid. An empty query lists everything that is
    /// not hidden, sorted by name. Otherwise hidden apps are searchable too,
    /// best match first: name prefix, word prefix, substring, then letters in
    /// order ("ffx" finds Firefox). The bundle id matches as a substring.
    public static func filter(_ apps: [AppEntry], query: String, hidden: IDList) -> [AppEntry] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty {
            return apps.filter { !hidden.contains($0.id) }.sorted(by: byName)
        }
        return apps
            .compactMap { app in score(app, q).map { (app, $0) } }
            .sorted { $0.1 != $1.1 ? $0.1 < $1.1 : byName($0.0, $1.0) }
            .map(\.0)
    }

    private static func byName(_ a: AppEntry, _ b: AppEntry) -> Bool {
        a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
    }

    private static func score(_ app: AppEntry, _ q: String) -> Int? {
        let name = app.name.lowercased()
        if name.hasPrefix(q) { return 0 }
        if name.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).contains(where: { $0.hasPrefix(q) }) {
            return 1
        }
        if name.contains(q) { return 2 }
        if app.id.lowercased().contains(q) { return 3 }
        return isSubsequence(q, of: name) ? 4 : nil
    }

    private static func isSubsequence(_ needle: String, of haystack: String) -> Bool {
        var it = haystack.makeIterator()
        for c in needle {
            var found = false
            while let h = it.next() {
                if h == c { found = true; break }
            }
            if !found { return false }
        }
        return true
    }
}

public enum SearchEngine {
    /// Web search URL for the launchpad fallback. Unknown engines use DuckDuckGo.
    public static func url(for query: String, engine: String) -> URL? {
        let base: String
        switch engine.lowercased() {
        case "google": base = "https://www.google.com/search"
        case "bing": base = "https://www.bing.com/search"
        default: base = "https://duckduckgo.com/"
        }
        var components = URLComponents(string: base)
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        return components?.url
    }
}
