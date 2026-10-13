import CoreWLAN
import Observation

/// Wi-Fi power and connection state through CoreWLAN events.
@MainActor
@Observable
final class WiFiService: NSObject, CWEventDelegate {
    static let shared = WiFiService()

    private(set) var isPowerOn = false
    private(set) var isConnected = false
    /// nil without Location permission, which macOS requires to read the name.
    private(set) var ssid: String?

    @ObservationIgnored private let client = CWWiFiClient.shared()

    private override init() {
        super.init()
        client.delegate = self
        for event in [CWEventType.powerDidChange, .ssidDidChange, .linkDidChange] {
            try? client.startMonitoringEvent(with: event)
        }
        refresh()
    }

    var symbolName: String {
        if !isPowerOn { return "wifi.slash" }
        return isConnected ? "wifi" : "wifi.exclamationmark"
    }

    var subtitle: String {
        if !isPowerOn { return "Off" }
        if let ssid { return ssid }
        return isConnected ? "Connected" : "Not connected"
    }

    func refresh() {
        let interface = client.interface()
        isPowerOn = interface?.powerOn() ?? false
        ssid = isPowerOn ? interface?.ssid() : nil
        isConnected = isPowerOn && (ssid != nil || (interface?.rssiValue() ?? 0) != 0)
    }

    func togglePower() {
        try? client.interface()?.setPower(!isPowerOn)
        refresh()
    }

    // CWEventDelegate callbacks arrive on an arbitrary queue.
    nonisolated func powerStateDidChangeForWiFiInterface(withName interfaceName: String) {
        Task { @MainActor in WiFiService.shared.refresh() }
    }

    nonisolated func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        Task { @MainActor in WiFiService.shared.refresh() }
    }

    nonisolated func linkDidChangeForWiFiInterface(withName interfaceName: String) {
        Task { @MainActor in WiFiService.shared.refresh() }
    }
}
