import Foundation
import Observation

/// System clock for the status area, updated once per second.
@MainActor
@Observable
final class ClockService {
    static let shared = ClockService()

    private(set) var timeString: String = ""
    private(set) var dateString: String = ""
    private(set) var shortDateString: String = ""

    @ObservationIgnored private var timer: Timer?

    private init() {
        update()
        let t = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.update() }
        }
        t.tolerance = 0.5
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func update() {
        let now = Date()
        let tf = DateFormatter()
        tf.timeStyle = .short
        timeString = tf.string(from: now)

        let df = DateFormatter()
        df.dateStyle = .full
        dateString = df.string(from: now)

        let sdf = DateFormatter()
        sdf.dateFormat = "MMM d"
        shortDateString = sdf.string(from: now)
    }
}
