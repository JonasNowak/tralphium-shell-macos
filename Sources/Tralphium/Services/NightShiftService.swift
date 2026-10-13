import Darwin
import Foundation
import ObjectiveC
import Observation

/// Night Shift (the Linux "Night Light") through the private
/// `CBBlueLightClient` class of CoreBrightness. Everything is looked up at
/// runtime; when the class or a selector is missing the toggle is hidden.
@MainActor
@Observable
final class NightShiftService {
    static let shared = NightShiftService()

    private(set) var isOn = false
    let isAvailable: Bool

    @ObservationIgnored private let client: NSObject?

    private typealias SetEnabled = @convention(c) (AnyObject, Selector, Bool) -> Bool
    private typealias GetStatus = @convention(c) (AnyObject, Selector, UnsafeMutableRawPointer) -> Bool

    private static let setEnabledSelector = NSSelectorFromString("setEnabled:")
    private static let statusSelector = NSSelectorFromString("getBlueLightStatus:")

    private init() {
        _ = dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness", RTLD_LAZY)
        let made = (NSClassFromString("CBBlueLightClient") as? NSObject.Type)?.init()
        let usable = made?.responds(to: Self.setEnabledSelector) == true
            && made?.responds(to: Self.statusSelector) == true
        client = usable ? made : nil
        isAvailable = usable
        refresh()
    }

    func refresh() {
        guard let client,
              let imp = class_getMethodImplementation(type(of: client), Self.statusSelector) else { return }
        // The status struct starts with `BOOL active`. A zeroed buffer larger
        // than the struct keeps this safe if Apple grows it.
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: 128, alignment: 16)
        defer { buffer.deallocate() }
        buffer.initializeMemory(as: UInt8.self, repeating: 0, count: 128)
        let getStatus = unsafeBitCast(imp, to: GetStatus.self)
        if getStatus(client, Self.statusSelector, buffer) {
            isOn = buffer.load(as: UInt8.self) != 0
        }
    }

    func toggle() {
        guard let client,
              let imp = class_getMethodImplementation(type(of: client), Self.setEnabledSelector) else { return }
        let setEnabled = unsafeBitCast(imp, to: SetEnabled.self)
        if setEnabled(client, Self.setEnabledSelector, !isOn) { isOn.toggle() }
    }
}
