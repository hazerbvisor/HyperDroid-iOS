import SwiftUI

struct HDTaskbarView: View {
    let metrics: HDMetrics
    let windows: [HDWindowState]
    let activeWindowID: UUID?
    let startMenuVisible: Bool
    let onToggleStart: () -> Void
    let onOpen: (HDAppEntry.Kind) -> Void
    let onFocus: (UUID) -> Void
    let onToggleMore: () -> Void
    let onToggleActionCenter: () -> Void
    let onToggleCalendar: () -> Void

    @Environment(\.colorScheme) private var scheme
    @AppStorage("hd.taskbarAlignment") private var alignment = "Center"
    @AppStorage("hd.taskbarShowWidgets") private var showWidgets = true
    @AppStorage("hd.taskbarShowClock") private var showClock = true
    @AppStorage("hd.taskbarShowSeconds") private var showSeconds = false
    @AppStorage("hd.use24Hour") private var use24Hour = false
    @AppStorage("hd.transparency") private var transparency = true
    @AppStorage("hd.accentColor") private var accentColor = "Blue"

    private var p: HDPalette { HDPalette(scheme: scheme) }

    var body: some View {
        ZStack {
            p.taskbar.opacity(transparency ? 0.94 : 1.0)

            Rectangle()
                .fill(p.border.opacity(0.65))
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
                    Spacer()
                }
            }

            HStack(spacing: 2) {
                HDTaskbarIcon(
                    asset: "app_startmenu_btn",
                    iconSize: metrics.taskbarAppSize,
                    buttonSize: metrics.taskbarButtonSize,
                    active: startMenuVisible,
                    accent: p.primary,
                    action: onToggleStart
                )

                ForEach([HDAppEntry.builtIns[1], HDAppEntry.builtIns[0], HDAppEntry.builtIns[2]]) { app in
                    let open = windows.first(where: { $0.kind.asset == app.asset })
                    HDTaskbarIcon(
                        asset: app.asset,
                        iconSize: metrics.taskbarAppSize,
                        buttonSize: metrics.taskbarButtonSize,
                        active: open?.id == activeWindowID,
                        accent: p.primary
                    ) {
                        if let open {
                            onFocus(open.id)
                        } else {
                            onOpen(app.kind)
                        }
                    }
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: alignment == "Left" ? .leading : .center
            )
            .padding(.leading, alignment == "Left" ? (showWidgets ? metrics.taskbarButtonSize + 4 : 4) : 0)

            HStack(spacing: 0) {
                Spacer()

                HDBitmapButton(
                    asset: "ui_taskbar_btn_more",
                    size: 15,
                    p: p,
                    action: onToggleMore
                )
                .frame(width: 30, height: metrics.taskbarHeight)

                Button(action: onToggleActionCenter) {
                    HStack(spacing: 4) {
                        HDImage(name: "ui_tb_globe_prohibited_24_regular", template: true, tint: p.text)
                            .frame(width: 15, height: 15)
                        HDImage(name: "ui_tb_speaker_2_24_regular", template: true, tint: p.text)
                            .frame(width: 15, height: 15)
                        HDImage(name: "ui_tb_battery_10_24", template: true, tint: p.text)
                            .frame(width: 15, height: 15)
                    }
                    .padding(.horizontal, 6)
                    .frame(height: metrics.taskbarHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if showClock {
                    Button(action: onToggleCalendar) {
                        HStack(spacing: 5) {
                            TimelineView(.periodic(from: .now, by: showSeconds ? 1 : 30)) { context in
                                VStack(alignment: .trailing, spacing: -2) {
                                    Text(clockText(context.date))
                                    Text(context.date, format: .dateTime.day().month().year())
                                }
                                .font(.system(size: 9.5))
                            }

                            HDImage(name: "ui_tb_alert_24_regular", template: true, tint: p.text)
                                .frame(width: 15, height: 15)
                        }
                        .padding(.leading, 6)
                        .padding(.trailing, 7)
                        .frame(height: metrics.taskbarHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .foregroundColor(p.text)
        }
        .frame(height: metrics.taskbarHeight)
        .padding(.horizontal, metrics.taskbarMarginHorizontal)
        .padding(.bottom, metrics.taskbarMarginBottom)
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

private struct HDTaskbarIcon: View {
    let asset: String
    let iconSize: CGFloat
    let buttonSize: CGFloat
    let active: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottom) {
                HDImage(name: asset)
                    .frame(width: iconSize, height: iconSize)
                    .frame(width: buttonSize, height: buttonSize)

                Capsule()
                    .fill(accent)
                    .frame(width: active ? 16 : 0, height: 3)
                    .opacity(active ? 1 : 0)
                    .padding(.bottom, 2)
                    .animation(.easeOut(duration: 0.16), value: active)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
