import AppKit
import SwiftUI
import TralphiumCore

/// Fullscreen overlay application launcher with fuzzy search and web fallback.
struct LaunchpadView: View {
    @Binding var query: String
    var onClose: () -> Void

    @State private var showHiddenApps = false
    @FocusState private var isSearchFocused: Bool
    private let catalog = AppCatalog.shared

    private var filteredApps: [AppEntry] {
        AppSearch.filter(catalog.apps, query: query, hidden: ListStore.hidden.list)
    }

    private var hiddenApps: [AppEntry] {
        catalog.apps
            .filter { ListStore.hidden.contains($0.id) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        let p = ThemeStore.shared.palette

        VStack(spacing: 14) {
            // Search Bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(p.accent))

                TextField("Search applications...", text: $query)
                    .font(.system(size: 15))
                    .textFieldStyle(.plain)
                    .foregroundColor(Color(p.textForeground))
                    .focused($isSearchFocused)
                    .onSubmit {
                        handleEnter()
                    }

                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(p.textSecondary))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(Color(p.hover).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color(p.panelBorder), lineWidth: 1)
            }

            // Application Grid or Web Fallback
            if filteredApps.isEmpty && !query.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Text("No matching applications")
                        .font(.system(size: 14))
                        .foregroundColor(Color(p.textSecondary))

                    HStack(spacing: 12) {
                        Button {
                            handleWebSearch()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "globe")
                                Text("Search web for \"\(query)\"")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(p.accent))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(p.hover))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        Button {
                            let target = query
                            query = ""
                            onClose()
                            Task {
                                await WebAppService.create(url: target)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.app.fill")
                                Text("Install as Web App")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(p.accent))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(p.hover))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                            ForEach(filteredApps) { app in
                                LaunchpadAppItemView(app: app) {
                                    Launch.app(at: app.path)
                                    onClose()
                                }
                            }
                        }

                        if query.isEmpty && !hiddenApps.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Divider()
                                    .padding(.vertical, 4)

                                Button {
                                    withAnimation(.snappy(duration: 0.2)) {
                                        showHiddenApps.toggle()
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: showHiddenApps ? "chevron.down" : "chevron.right")
                                            .font(.system(size: 11, weight: .semibold))
                                        Text("Hidden applications (\(hiddenApps.count))")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundColor(Color(p.textSecondary))
                                }
                                .buttonStyle(.plain)

                                if showHiddenApps {
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                                        ForEach(hiddenApps) { app in
                                            LaunchpadAppItemView(app: app) {
                                                Launch.app(at: app.path)
                                                onClose()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 2)
                }
                .frame(maxHeight: .infinity)
            }

            // Footer Info
            HStack {
                Text("ESC to close • ⌥Space to toggle")
                Spacer()
            }
            .font(.system(size: 11))
            .foregroundColor(Color(p.textSecondary))
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(p.panelBackground))
        .background(
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: p.panelRadius))
        )
        .clipShape(RoundedRectangle(cornerRadius: p.panelRadius))
        .overlay {
            RoundedRectangle(cornerRadius: p.panelRadius)
                .strokeBorder(Color(p.panelBorder), lineWidth: p.panelBorderWidth)
        }
        .onAppear {
            isSearchFocused = true
        }
    }

    private func handleEnter() {
        if let first = filteredApps.first {
            Launch.app(at: first.path)
            onClose()
        } else if !query.isEmpty {
            handleWebSearch()
        }
    }

    private func handleWebSearch() {
        let engine = ConfigStore.shared.config.searchEngine
        if let url = SearchEngine.url(for: query, engine: engine) {
            Launch.url(url)
            onClose()
        }
    }
}

private struct LaunchpadAppItemView: View {
    let app: AppEntry
    let onLaunch: () -> Void

    @State private var isHovered = false

    var body: some View {
        let p = ThemeStore.shared.palette
        let icon = AppCatalog.shared.icon(forPath: app.path)

        Button(action: onLaunch) {
            VStack(spacing: 6) {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 44, height: 44)

                Text(app.name)
                    .font(.system(size: 11))
                    .foregroundColor(Color(p.textForeground))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 92)
            }
            .frame(width: 98, height: 90)
            .background(isHovered ? Color(p.hover) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(app.name)
        .contextMenu {
            let isPinned = ListStore.pins.contains(app.id)
            Button(isPinned ? "Unpin from Shelf" : "Pin to Shelf") {
                ListStore.pins.toggle(app.id)
            }
            let isHidden = ListStore.hidden.contains(app.id)
            Button(isHidden ? "Unhide in Launchpad" : "Hide from Launchpad") {
                ListStore.hidden.toggle(app.id)
            }
        }
    }
}
