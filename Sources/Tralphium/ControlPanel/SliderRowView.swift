import SwiftUI
import TralphiumCore

/// Row with an icon button, custom-styled slider, and optional trailing button.
struct SliderRowView: View {
    let icon: String
    var trailingIcon: String? = nil
    @Binding var value: Double
    var isLeadingButtonEnabled: Bool = true
    var onMoved: (Double) -> Void
    var onIconClicked: (() -> Void)? = nil
    var onTrailingClicked: (() -> Void)? = nil

    @State private var isIconHovered = false
    @State private var isTrailingHovered = false

    var body: some View {
        let p = ThemeStore.shared.palette

        HStack(spacing: 12) {
            // Leading Icon Button
            Button {
                onIconClicked?()
            } label: {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(p.iconColor))
                    .frame(width: 32, height: 32)
                    .background(isIconHovered ? Color(p.hover).opacity(0.8) : Color(p.hover).opacity(0.35))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!isLeadingButtonEnabled)
            .onHover { isIconHovered = $0 }

            // Custom Styled Slider
            GeometryReader { geo in
                let width = geo.size.width
                let clamped = min(max(value, 0), 1)
                let xOffset = clamped * width

                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color(p.textForeground).opacity(0.18))
                        .frame(height: 5)

                    // Filled track
                    Capsule()
                        .fill(Color(p.accent))
                        .frame(width: max(xOffset, 0), height: 5)

                    // Thumb
                    Circle()
                        .fill(Color(p.textForeground))
                        .frame(width: 14, height: 14)
                        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                        .offset(x: max(min(xOffset - 7, width - 14), 0))
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let fraction = min(max(gesture.location.x / width, 0), 1)
                            value = fraction
                            onMoved(fraction)
                        }
                )
            }
            .frame(height: 24)

            // Trailing Button (e.g. chevron for audio sinks)
            if let trailingIcon {
                Button {
                    onTrailingClicked?()
                } label: {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(p.iconColor))
                        .frame(width: 32, height: 32)
                        .background(isTrailingHovered ? Color(p.hover).opacity(0.8) : Color(p.hover).opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .onHover { isTrailingHovered = $0 }
            } else {
                Color.clear
                    .frame(width: 32, height: 32)
            }
        }
    }
}
