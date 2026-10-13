import Foundation
import Testing
@testable import TralphiumCore

@Suite struct ConfigTests {
    @Test func defaultsWhenFileMissingOrBroken() {
        #expect(TralphiumConfig(json: nil) == TralphiumConfig())
        #expect(TralphiumConfig(json: Data("not json".utf8)) == TralphiumConfig())
        #expect(TralphiumConfig(json: Data("[1,2]".utf8)) == TralphiumConfig())
    }

    @Test func readsKnownKeys() {
        let json = """
        {"theme":"kanagawa","shelfPosition":"left","shelfAutoHide":true,
         "searchEngine":"Google","shelfOpacity":0.4,"apps":{"terminal":"iTerm"}}
        """
        let c = TralphiumConfig(json: Data(json.utf8))
        #expect(c.theme == "kanagawa")
        #expect(c.shelfPosition == .left)
        #expect(c.shelfAutoHide)
        #expect(c.searchEngine == "Google")
        #expect(c.shelfOpacity == 0.4)
        #expect(c.apps.terminal == "iTerm")
        #expect(c.apps.fileManager == "Finder")
    }

    @Test func wrongTypesAndUnknownValuesFallBack() {
        let json = #"{"theme":5,"shelfPosition":"top","shelfAutoHide":"yes","apps":"x"}"#
        #expect(TralphiumConfig(json: Data(json.utf8)) == TralphiumConfig())
    }

    @Test func encodingKeepsUnknownKeys() throws {
        let existing = Data(#"{"legacyKey":42,"apps":{"custom":"x"}}"#.utf8)
        var c = TralphiumConfig()
        c.theme = "one-dark"
        let out = c.encoded(merging: existing)
        let dict = try #require(try JSONSerialization.jsonObject(with: out) as? [String: Any])
        #expect(dict["legacyKey"] as? Int == 42)
        #expect((dict["apps"] as? [String: Any])?["custom"] as? String == "x")
        #expect(TralphiumConfig(json: out).theme == "one-dark")
    }

    @Test func roundTrip() {
        var c = TralphiumConfig()
        c.shelfPosition = .right
        c.shelfAutoHide = true
        c.dndShortcut = "Focus"
        c.shelfOpacity = 0.65
        #expect(TralphiumConfig(json: c.encoded(merging: nil)) == c)
    }
}

@Suite struct IDListTests {
    @Test func dedupesCaseInsensitively() {
        let l = IDList(["com.a.App", "COM.A.APP", "com.b.App", ""])
        #expect(l.ids == ["com.a.App", "com.b.App"])
        #expect(l.contains("com.B.app"))
    }

    @Test func toggleAddsAndRemoves() {
        var l = IDList()
        l.toggle("x")
        #expect(l.ids == ["x"])
        l.toggle("X")
        #expect(l.ids.isEmpty)
    }

    @Test func insertMovesExisting() {
        var l = IDList(["a", "b", "c"])
        l.insert("c", at: 0)
        #expect(l.ids == ["c", "a", "b"])
        l.insert("d", at: 99)
        #expect(l.ids == ["c", "a", "b", "d"])
        l.insert("e", at: 1)
        #expect(l.ids == ["c", "e", "a", "b", "d"])
        l.insert("c", at: 99)
        #expect(l.ids == ["e", "a", "b", "d", "c"])
    }

    @Test func moveIgnoresInvalidIndexes() {
        var l = IDList(["a", "b"])
        l.move(from: 0, to: 5)
        l.move(from: -1, to: 0)
        #expect(l.ids == ["a", "b"])
        l.move(from: 0, to: 1)
        #expect(l.ids == ["b", "a"])
    }

    @Test func jsonRoundTripAndGarbage() {
        let l = IDList(["a", "b"])
        #expect(IDList(json: l.jsonData()) == l)
        #expect(IDList(json: Data("{}".utf8)).ids.isEmpty)
        #expect(IDList(json: nil).ids.isEmpty)
    }
}

@Suite struct AppSearchTests {
    let apps = [
        AppEntry(id: "org.mozilla.firefox", name: "Firefox", path: "/A/Firefox.app"),
        AppEntry(id: "com.apple.Safari", name: "Safari", path: "/A/Safari.app"),
        AppEntry(id: "com.apple.ActivityMonitor", name: "Activity Monitor", path: "/A/AM.app"),
        AppEntry(id: "com.example.Hidden", name: "Zebra", path: "/A/Z.app"),
    ]

    @Test func emptyQuerySortsAndHidesHidden() {
        let r = AppSearch.filter(apps, query: " ", hidden: IDList(["com.example.hidden"]))
        #expect(r.map(\.name) == ["Activity Monitor", "Firefox", "Safari"])
    }

    @Test func queryFindsHiddenApps() {
        let r = AppSearch.filter(apps, query: "zeb", hidden: IDList(["com.example.Hidden"]))
        #expect(r.map(\.name) == ["Zebra"])
    }

    @Test func rankingPrefixBeforeWordBeforeSubstring() {
        let list = [
            AppEntry(id: "1", name: "Big Monitor Tool", path: ""),
            AppEntry(id: "2", name: "Monitor", path: ""),
            AppEntry(id: "3", name: "Activity Monitor", path: ""),
            AppEntry(id: "4", name: "Demonitor", path: ""),
        ]
        let r = AppSearch.filter(list, query: "monitor", hidden: IDList())
        // "Activity Monitor" and "Big Monitor Tool" both match on a word prefix: name order decides.
        #expect(r.map(\.id) == ["2", "3", "1", "4"])
    }

    @Test func subsequenceAndBundleIDMatch() {
        #expect(AppSearch.filter(apps, query: "ffx", hidden: IDList()).map(\.name) == ["Firefox"])
        #expect(AppSearch.filter(apps, query: "mozilla", hidden: IDList()).map(\.name) == ["Firefox"])
        #expect(AppSearch.filter(apps, query: "qqq", hidden: IDList()).isEmpty)
    }
}

@Suite struct SearchEngineTests {
    @Test func buildsAndEscapesQueries() {
        #expect(SearchEngine.url(for: "a b&c", engine: "Google")?.absoluteString
            == "https://www.google.com/search?q=a%20b%26c")
        #expect(SearchEngine.url(for: "x", engine: "unknown")?.host == "duckduckgo.com")
        #expect(SearchEngine.url(for: "x", engine: "BING")?.host == "www.bing.com")
    }
}

@Suite struct BatteryStatusTests {
    func status(_ cap: Int, charging: Bool = false, ac: Bool = false, charged: Bool = false) -> BatteryStatus {
        BatteryStatus(capacity: cap, isCharging: charging, onACPower: ac, isCharged: charged)
    }

    @Test func descriptions() {
        #expect(status(40).description == "40% left")
        #expect(status(40, charging: true, ac: true).description == "40% - Charging")
        #expect(status(80, ac: true).description == "80% - Plugged in")
        #expect(status(100, ac: true, charged: true).description == "Battery full")
        #expect(status(95, ac: true, charged: true).description == "95% - Plugged in")
    }

    @Test func symbols() {
        #expect(status(100).symbolName == "battery.100")
        #expect(status(50).symbolName == "battery.50")
        #expect(status(5).symbolName == "battery.0")
        #expect(status(5, charging: true).symbolName == "battery.100.bolt")
    }

    @Test func toastsOnPlugAndThresholds() {
        #expect(BatteryStatus.toast(from: nil, to: status(10)) == nil)
        #expect(BatteryStatus.toast(from: status(50), to: status(49)) == nil)
        #expect(BatteryStatus.toast(from: status(50), to: status(50, ac: true))?.title == "Charger connected")
        #expect(BatteryStatus.toast(from: status(50, ac: true), to: status(50))?.title == "Running on battery")
        #expect(BatteryStatus.toast(from: status(21), to: status(20))?.title == "Battery low")
        #expect(BatteryStatus.toast(from: status(11), to: status(10))?.title == "Battery critically low")
        #expect(BatteryStatus.toast(from: status(21, ac: true), to: status(20, ac: true)) == nil)
    }
}

@Suite struct ShellCommandTests {
    @Test func parsesCommands() {
        func parse(_ s: String) -> ShellCommand? { URL(string: s).flatMap(ShellCommand.init(url:)) }
        #expect(parse("tralphium://toggleLaunchpad") == .toggleLaunchpad)
        #expect(parse("tralphium://openLaunchpad") == .openLaunchpad)
        #expect(parse("tralphium://closeLaunchpad") == .closeLaunchpad)
        #expect(parse("tralphium://TOGGLECONTROLPANEL") == .toggleControlPanel)
        #expect(parse("tralphium://openPowerMenu") == .openPowerMenu)
        #expect(parse("tralphium://takeScreenshot") == .takeScreenshot)
        #expect(parse("tralphium://toggleTheme") == .toggleTheme)
        #expect(parse("tralphium://reloadConfig") == .reloadConfig)
        #expect(parse("tralphium://unhideAll") == .unhideAll)
        #expect(parse("tralphium://unhide?id=com.apple.Safari") == .unhide("com.apple.Safari"))
        #expect(parse("tralphium://unhide/com.apple.Safari") == .unhide("com.apple.Safari"))
        #expect(parse("tralphium://unhideInBackground?id=com.apple.Safari") == .unhideInBackground("com.apple.Safari"))
        #expect(parse("tralphium://unhideinbackground/com.apple.Safari") == .unhideInBackground("com.apple.Safari"))
        #expect(parse("tralphium://hide?id=com.apple.Safari") == .hide("com.apple.Safari"))
        #expect(parse("tralphium://hide/com.apple.Safari") == .hide("com.apple.Safari"))
        #expect(parse("tralphium://unhide") == nil)
        #expect(parse("tralphium://unhideInBackground") == nil)
        #expect(parse("tralphium://hide") == nil)
        #expect(parse("tralphium://setTheme?name=nord") == .setTheme("nord"))
        #expect(parse("tralphium://setTheme/one-dark") == .setTheme("one-dark"))
        #expect(parse("tralphium://setTheme") == nil)
        #expect(parse("tralphium://nope") == nil)
        #expect(parse("https://toggleLaunchpad") == nil)
    }
}

@Suite struct TaskbarModelTests {
    @Test func pinnedFirstThenUnpinnedRunning() {
        let items = TaskbarModel.items(
            pinned: IDList(["a", "b"]), running: ["c", "B", "a", "c", "d"])
        #expect(items.map(\.id) == ["a", "b", "c", "d"])
        #expect(items.map(\.isPinned) == [true, true, false, false])
    }

    @Test func themeCycleWraps() {
        #expect(ThemePalette.next(after: "nord").name == "catppuccin-mocha")
        #expect(ThemePalette.next(after: "one-light").name == "nord")
        #expect(ThemePalette.next(after: "garbage").name == "nord")
    }
}
