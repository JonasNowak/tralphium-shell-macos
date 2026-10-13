import AppKit
import SwiftUI
import TralphiumCore

/// Fullscreen overlay application launcher with fuzzy search and web fallback.
struct LaunchpadView: View {
    @Binding var query: String
    var onClose: () -> Void

    @FocusState private var isSearchFocused: Bool
    private let catalog = AppCatalog.shared

    private var filteredApps: [AppEntry] {
        AppSearch.filter(catalog.apps, query: query, hidden: ListStore.hidden.list)
    }

    var body: some View {
        let p = ThemeStore.shared.palette

        ZStack {
            // Semi-transparent backdrop blur; clicking outside closes
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    onClose()
                }

            // Main Launchpad Card
            VStack(spacing: 16) {
                // Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(p.accent))

                    TextField("Search applications...", text: $query)
                        .font(.system(size: 16))
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
                .frame(height: 44)
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
                        Spacer()
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 5), spacing: 16) {
                            ForEach(filteredApps) { app in
                                LaunchpadAppItemView(app: app) {
                                    Launch.app(at: app.path)
                                    onClose()
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                    }
                    .frame(maxHeight: .infinity)
                }

                // Footer Info
                HStack {
                    Text("ESC to close • ⌥Space to toggle")
                    Spacer()
                    Text("\(catalog.apps.count) applications installed")
                }
                .font(.system(size: 11))
                .foregroundColor(Color(p.textSecondary))
            }
            .padding(20)
            .frame(width: 680, height: 500)
            .background(Color(p.panelBackground))
            .clipShape(RoundedRectangle(cornerRadius: p.panelRadius))
            .overlay {
                RoundedRectangle(cornerRadius: p.panelRadius)
                    .strokeBorder(Color(p.panelBorder), lineWidth: p.panelBorderWidth)
            }
            // Catch clicks inside the card so they don't dismiss the window
            .contentShape(RoundedRectangle(cornerRadius: p.panelRadius))
            .onTapGesture {}
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
            VStack(spacing: 8) {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 48, height: 48)

                Text(app.name)
                    .font(.system(size: 12))
                    .foregroundColor(Color(p.textForeground))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 100)
            }
            .frame(width: 110, height: 96)
            .background(isHovered ? Color(p.hover) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(app.name)
    }
}
