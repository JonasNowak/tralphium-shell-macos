import Foundation
import IOKit.ps
import Observation
import TralphiumCore

/// Battery state from IOKit's power source run-loop notification (no polling).
@MainActor
@Observable
final class BatteryService {
    static let shared = BatteryService()

    /// nil on Macs without a battery.
    private(set) var status: BatteryStatus?
    /// Called with the previous and new reading after a change.
    @ObservationIgnored var onChange: ((BatteryStatus?, BatteryStatus) -> Void)?

    private init() {
        status = Self.read()
        let context = Unmanaged.passUnretained(self).toOpaque()
        let callback: IOPowerSourceCallbackType = { context in
            guard let context else { return }
            let service = Unmanaged<BatteryService>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { service.update() }
        }
        if let source = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }
    }

    private func update() {
        guard let new = Self.read(), new != status else { return }
        let old = status
        status = new
        onChange?(old, new)
    }

    private static func read() -> BatteryStatus? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return nil }
        for source in list {
            guard let d = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  d[kIOPSTypeKey] as? String == kIOPSInternalBatteryType else { continue }
            let current = d[kIOPSCurrentCapacityKey] as? Int ?? 0
            let max = d[kIOPSMaxCapacityKey] as? Int ?? 100
            return BatteryStatus(
                capacity: max > 0 ? Int((Double(current) / Double(max) * 100).rounded()) : current,
                isCharging: d[kIOPSIsChargingKey] as? Bool ?? false,
                onACPower: d[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue,
                isCharged: d[kIOPSIsChargedKey] as? Bool ?? false)
        }
        return nil
    }
}
