import AppKit
import SwiftUI

/// Modal prompt to install a Chrome OS-style Web Application using Helium.
@MainActor
enum WebAppPrompt {
    static func show() {
        let alert = NSAlert()
        alert.messageText = "Add Web Application"
        alert.informativeText = "Enter a website URL to create a standalone Chrome OS-style web app powered by Helium:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Install")
        alert.addButton(withTitle: "Cancel")

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 340, height: 60))

        let urlLabel = NSTextField(labelWithString: "URL:")
        urlLabel.frame = NSRect(x: 0, y: 34, width: 45, height: 20)
        urlLabel.font = .systemFont(ofSize: 12, weight: .semibold)

        let urlField = NSTextField(frame: NSRect(x: 50, y: 32, width: 290, height: 24))
        urlField.placeholderString = "https://youtube.com"

        let nameLabel = NSTextField(labelWithString: "Name:")
        nameLabel.frame = NSRect(x: 0, y: 4, width: 45, height: 20)
        nameLabel.font = .systemFont(ofSize: 12, weight: .semibold)

        let nameField = NSTextField(frame: NSRect(x: 50, y: 2, width: 290, height: 24))
        nameField.placeholderString = "Optional (auto-detected if empty)"

        container.addSubview(urlLabel)
        container.addSubview(urlField)
        container.addSubview(nameLabel)
        container.addSubview(nameField)

        alert.accessoryView = container

        // Bring to front and run
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            let urlText = urlField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let nameText = nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !urlText.isEmpty else { return }

            Task {
                await WebAppService.create(
                    url: urlText,
                    name: nameText.isEmpty ? nil : nameText,
                    launchAfterCreation: true
                )
            }
        }
    }
}
