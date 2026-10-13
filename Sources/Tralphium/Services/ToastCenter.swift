import AppKit
import Observation
import TralphiumCore

/// Short messages from the shell itself (battery, screenshot). macOS gives
/// apps no way to intercept other apps' notifications, so this stack is only
/// for the shell's own events.
@MainActor
@Observable
final class ToastCenter {
    static let shared = ToastCenter()

    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let content: ToastContent
    }

    private(set) var toasts: [Toast] = []
    /// Called after the stack changes, so the window can resize or hide.
    @ObservationIgnored var onChange: (() -> Void)?

    private init() {}

    func show(_ content: ToastContent) {
        guard ConfigStore.shared.config.notificationsEnabled else { return }
        let toast = Toast(content: content)
        toasts.append(toast)
        onChange?()
        Task {
            try? await Task.sleep(for: .seconds(4))
            dismiss(toast.id)
        }
    }

    func dismiss(_ id: UUID) {
        toasts.removeAll { $0.id == id }
        onChange?()
    }
}
