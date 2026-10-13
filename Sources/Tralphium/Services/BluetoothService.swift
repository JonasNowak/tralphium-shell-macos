import Darwin
import Observation

/// Bluetooth on/off. The public IOBluetooth API cannot switch the controller,
/// so this loads the two preference functions that `blueutil` and the system
/// menu use, with `dlsym`. Without them the toggle is hidden.
@MainActor
@Observable
final class BluetoothService {
    static let shared = BluetoothService()

    private typealias GetPower = @convention(c) () -> Int32
    private typealias SetPower = @convention(c) (Int32) -> Int32

    private(set) var isOn = false
    let isAvailable: Bool

    @ObservationIgnored private var getPower: GetPower?
    @ObservationIgnored private var setPower: SetPower?

    private init() {
        let handle = dlopen("/System/Library/Frameworks/IOBluetooth.framework/IOBluetooth", RTLD_LAZY)
        if let handle,
           let get = dlsym(handle, "IOBluetoothPreferenceGetControllerPowerState"),
           let set = dlsym(handle, "IOBluetoothPreferenceSetControllerPowerState") {
            getPower = unsafeBitCast(get, to: GetPower.self)
            setPower = unsafeBitCast(set, to: SetPower.self)
        }
        isAvailable = getPower != nil && setPower != nil
        refresh()
    }

    func refresh() {
        isOn = (getPower?() ?? 0) != 0
    }

    func toggle() {
        guard let setPower else { return }
        _ = setPower(isOn ? 0 : 1)
        isOn.toggle()
        // The controller needs a moment to switch; confirm the real state afterwards.
        Task {
            try? await Task.sleep(for: .seconds(1))
            refresh()
        }
    }
}
