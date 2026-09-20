import SwiftUI

struct HDTaskbarView: View {
    let metrics: HDMetrics
    let windows: [HDWindowState]
    let activeWindowID: UUID?
    let startMenuVisible: Bool
    let onToggleStart: () -> Void
    let onSearch: () -> Void
    let onOpen: (HDAppEntry.Kind) -> Void
    let onWindowAction: (UUID) -> Void
    let onToggleMore: () -> Void
    let onToggleActionCenter: () -> Void
    let onToggleCalendar: () -> Void

    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var system = HDSystemStatus.shared

    @AppStorage("hd.taskbarAlignment") private var alignment = "Center"
    @AppStorage("hd.taskbarShowWidgets") private var showWidgets = true
    @AppStorage("hd.taskbarSearchMode") private var searchMode = "Search box"
    @AppStorage("hd.taskbarShowClock") private var showClock = true
    @AppStorage("hd.taskbarShowSeconds") private var showSeconds = false
    @AppStorage("hd.use24Hour") private var use24Hour = false
    @AppStorage("hd.transparency") private var transparency = true

    private var p: HDPalette { HDPalette(scheme: scheme) }

    var body: some View {
        ZStack {
            HDGlassSurface(
                tint: p.taskbar,
                enabled: transparency,
                tintOpacity: scheme == .dark ? 0.58 : 0.72
            )

            Rectangle()
                .fill(p.border.opacity(0.55))
                .frame(height: 1)
                .frame(maxHeight: .infinity, alignment: .top)

            if showWidgets {
                HStack(spacing: 0) {
                    Button(action: {}) {
                        HDImage(name: "img_app_widget")
                            .frame(width: metrics.taskbarAppSize, height: metrics.taskbarAppSize)
                            .frame(width: metrics.taskbarButtonSize, height: metrics.taskbarButtonSize)
                    }
                    .buttonStyle(.plain)
                    .hdCursor(.hand)
                    Spacer()
                }
            }

            HStack(spacing: 4 * metrics.scale) {
                HDStartTaskbarButton(
                    asset: "app_startmenu_btn",
                    iconSize: metrics.taskbarAppSize,
                    buttonSize: metrics.taskbarButtonSize,
                    active: startMenuVisible,
                    action: onToggleStart
                )

                if searchMode == "Search box" {
                    Button(action: onSearch) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 13 * metrics.scale, weight: .medium))
                            Text("Search")
                                .font(.system(size: 12.5 * metrics.scale))
                            Spacer(minLength: 0)
                        }
                        .foregroundColor(p.text.opacity(0.88))
                        .padding(.horizontal, 12 * metrics.scale)
                        .frame(width: metrics.taskbarSearchWidth, height: metrics.taskbarSearchHeight)
                        .background(
                            RoundedRectangle(cornerRadius: 7 * metrics.scale)
                                .fill(Color.white.opacity(scheme == .dark ? 0.10 : 0.55))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 7 * metrics.scale)
                                .stroke(p.border.opacity(0.42), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .hdCursor(.hand)
                } else if searchMode == "Search icon" {
                    Button(action: onSearch) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14 * metrics.scale, weight: .medium))
                            .foregroundColor(p.text)
                            .frame(width: metrics.taskbarButtonSize, height: metrics.taskbarButtonSize)
                    }
                    .buttonStyle(.plain)
                    .hdCursor(.hand)
                }

                ForEach([HDAppEntry.builtIns[1], HDAppEntry.builtIns[0], HDAppEntry.builtIns[2]]) { app in
                    let open = windows.first(where: { $0.kind.asset == app.asset })
                    HDTaskbarIcon(
                        asset: app.asset,
                        iconSize: metrics.taskbarAppSize,
                        buttonSize: metrics.taskbarButtonSize,
                        running: open != nil,
                        active: open?.id == activeWindowID && open?.minimized == false,
                        minimized: open?.minimized == true,
                        accent: p.primary
                    ) {
                        if let open {
                            onWindowAction(open.id)
                        } else {
                            onOpen(app.kind)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: alignment == "Left" ? .leading : .center)
            .padding(.leading, alignment == "Left" ? (showWidgets ? metrics.taskbarButtonSize + 4 : 4) : 0)

            HStack(spacing: 0) {
                Spacer()

                HDBitmapButton(
                    asset: "ui_taskbar_btn_more",
                    size: 15 * metrics.scale,
                    p: p,
                    action: onToggleMore
                )
                .frame(width: 30 * metrics.scale, height: metrics.taskbarHeight)

                Button(action: onToggleActionCenter) {
                    HStack(spacing: 5) {
                        Image(systemName: networkSymbol)
                            .font(.system(size: 13 * metrics.scale, weight: .medium))
                            .frame(width: 15 * metrics.scale, height: 15 * metrics.scale)

                        Image(systemName: system.outputVolume < 0.01 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 12 * metrics.scale, weight: .medium))
                            .frame(width: 15 * metrics.scale, height: 15 * metrics.scale)

                        ZStack(alignment: .topTrailing) {
                            Image(systemName: batterySymbol)
                                .font(.system(size: 14 * metrics.scale, weight: .medium))
                                .frame(width: 18 * metrics.scale, height: 15 * metrics.scale)

                            if system.charging {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 6 * metrics.scale, weight: .bold))
                                    .foregroundColor(p.primary)
                                    .offset(x: 3, y: -3)
                            }
                        }
                    }
                    .padding(.horizontal, 6 * metrics.scale)
                    .frame(height: metrics.taskbarHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .hdCursor(.hand)

                if showClock {
                    Button(action: onToggleCalendar) {
                        HStack(spacing: 5) {
                            TimelineView(.periodic(from: .now, by: showSeconds ? 1 : 30)) { context in
                                VStack(alignment: .trailing, spacing: -2) {
                                    Text(clockText(context.date))
                                    Text(context.date, format: .dateTime.day().month().year())
                                }
                                .font(.system(size: 9.5 * metrics.scale))
                            }

                            HDImage(name: "ui_tb_alert_24_regular", template: true, tint: p.text)
                                .frame(width: 15 * metrics.scale, height: 15 * metrics.scale)
                        }
                        .padding(.leading, 6 * metrics.scale)
                        .padding(.trailing, 7 * metrics.scale)
                        .frame(height: metrics.taskbarHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .hdCursor(.hand)
                }
            }
            .foregroundColor(p.text)
        }
        .frame(height: metrics.taskbarHeight)
        .padding(.horizontal, metrics.taskbarMarginHorizontal)
        .padding(.bottom, metrics.taskbarMarginBottom)
    }

    private var networkSymbol: String {
        guard system.networkConnected else { return "network.slash" }
        switch system.networkKind {
        case "Wi-Fi": return "wifi"
        case "Cellular": return "antenna.radiowaves.left.and.right"
        case "Ethernet": return "network"
        default: return "network"
        }
    }

    private var batterySymbol: String {
        switch system.batteryPercent {
        case 0..<13: return "battery.0"
        case 13..<38: return "battery.25"
        case 38..<63: return "battery.50"
        case 63..<88: return "battery.75"
        default: return "battery.100"
        }
    }

    private func clockText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        if use24Hour {
            formatter.dateFormat = showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            formatter.dateFormat = showSeconds ? "h:mm:ss a" : "h:mm a"
        }
        return formatter.string(from: date)
    }
}


private struct HDStartTaskbarButton: View {
    let asset: String
    let iconSize: CGFloat
    let buttonSize: CGFloat
    let active: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HDImage(name: asset)
                .frame(width: iconSize, height: iconSize)
                .frame(width: buttonSize, height: buttonSize)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            Color.white.opacity(
                                active
                                    ? (scheme == .dark ? 0.12 : 0.42)
                                    : (hovering ? (scheme == .dark ? 0.08 : 0.28) : 0)
                            )
                        )
                )
        }
        .buttonStyle(HDStartPressStyle(active: active))
        .onHover { hovering = $0 }
        .hdCursor(.hand)
        .animation(.easeOut(duration: 0.12), value: hovering)
        .animation(.spring(response: 0.28, dampingFraction: 0.68), value: active)
    }
}

private struct HDStartPressStyle: ButtonStyle {
    let active: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed
                    ? 0.84
                    : (active ? 1.04 : 1.0)
            )
            .animation(
                .spring(response: 0.22, dampingFraction: 0.58),
                value: configuration.isPressed
            )
            .animation(
                .spring(response: 0.30, dampingFraction: 0.62),
                value: active
            )
    }
}

private struct HDTaskbarIcon: View {
    let asset: String
    let iconSize: CGFloat
    let buttonSize: CGFloat
    let running: Bool
    let active: Bool
    let minimized: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottom) {
                HDImage(name: asset)
                    .frame(width: iconSize, height: iconSize)
                    .frame(width: buttonSize, height: buttonSize)

                Capsule()
                    .fill(active ? accent : Color.secondary.opacity(minimized ? 0.68 : 0.58))
                    .frame(width: active ? 16 : (running ? 7 : 0), height: 3)
                    .opacity(running ? 1 : 0)
                    .padding(.bottom, 2)
                    .animation(.spring(response: 0.22, dampingFraction: 0.82), value: active)
                    .animation(.easeOut(duration: 0.14), value: running)
                    .animation(.easeOut(duration: 0.14), value: minimized)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hdCursor(.hand)
    }
}

private struct HDBitmapButton: View {
    let asset: String
    let size: CGFloat
    let p: HDPalette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HDImage(name: asset, template: true, tint: p.text)
                .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }
}
