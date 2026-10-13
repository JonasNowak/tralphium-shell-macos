import Foundation

/// A short message for the shell's toast stack.
public struct ToastContent: Equatable, Sendable {
    /// SF Symbol name.
    public let symbol: String
    public let title: String
    public let message: String

    public init(symbol: String, title: String, message: String) {
        self.symbol = symbol
        self.title = title
        self.message = message
    }
}

public struct BatteryStatus: Equatable, Sendable {
    public var capacity: Int
    public var isCharging: Bool
    public var onACPower: Bool
    public var isCharged: Bool

    public init(capacity: Int, isCharging: Bool, onACPower: Bool, isCharged: Bool) {
        self.capacity = capacity
        self.isCharging = isCharging
        self.onACPower = onACPower
        self.isCharged = isCharged
    }

    public var description: String {
        if isCharged { return capacity >= 100 ? "Battery full" : "\(capacity)% - Plugged in" }
        if isCharging { return "\(capacity)% - Charging" }
        if onACPower { return "\(capacity)% - Plugged in" }
        return "\(capacity)% left"
    }

    /// SF Symbol for the status area.
    public var symbolName: String {
        if isCharging { return "battery.100.bolt" }
        switch capacity {
        case 88...: return "battery.100"
        case 63...: return "battery.75"
        case 38...: return "battery.50"
        case 13...: return "battery.25"
        default: return "battery.0"
        }
    }

    /// Toast for a change between two readings, if one is worth showing: plug
    /// in or out, and falling below 20% or 10% on battery.
    public static func toast(from old: BatteryStatus?, to new: BatteryStatus) -> ToastContent? {
        guard let old else { return nil }
        if new.onACPower != old.onACPower {
            return new.onACPower
                ? ToastContent(symbol: "powerplug", title: "Charger connected", message: new.description)
                : ToastContent(symbol: "battery.100", title: "Running on battery", message: new.description)
        }
        guard !new.onACPower else { return nil }
        for threshold in [10, 20] where old.capacity > threshold && new.capacity <= threshold {
            return ToastContent(
                symbol: "battery.25", title: threshold == 10 ? "Battery critically low" : "Battery low",
                message: "\(new.capacity)% left")
        }
        return nil
    }
}
