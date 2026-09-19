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
    private var p: HDPalette { HDPalette(scheme: scheme) }

    var body: some View {
        ZStack {
            p.taskbar
            Rectangle()
                .fill(p.border.opacity(0.65))
                .frame(height: 1)
                .frame(maxHeight: .infinity, alignment: .top)

            HStack(spacing: 0) {
                Button(action: {}) {
                    HDImage(name: "img_app_widget")
                        .frame(width: metrics.taskbarAppSize, height: metrics.taskbarAppSize)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                HStack(spacing: 0) {
                    HDTaskbarIcon(
                        asset: "app_startmenu_btn",
                        size: metrics.taskbarAppSize,
                        active: startMenuVisible,
                        action: onToggleStart
                    )

                    ForEach([HDAppEntry.builtIns[1], HDAppEntry.builtIns[0], HDAppEntry.builtIns[2]]) { app in
                        let open = windows.first(where: { $0.kind.asset == app.asset })
                        HDTaskbarIcon(
                            asset: app.asset,
                            size: metrics.taskbarAppSize,
                            active: open?.id == activeWindowID
                        ) {
                            if let open {
                                onFocus(open.id)
                            } else {
                                onOpen(app.kind)
                            }
                        }
                    }
                }
                .padding(.vertical, 3)

                Spacer(minLength: 0)

                HStack(spacing: 0) {
                    HDBitmapButton(
                        asset: "ui_taskbar_btn_more",
                        size: 18,
                        p: p,
                        action: onToggleMore
                    )
                    .padding(.horizontal, 8)

                    Button(action: onToggleActionCenter) {
                        HStack(spacing: 6) {
                            HDImage(
                                name: "ui_tb_globe_prohibited_24_regular",
                                template: true,
                                tint: p.text
                            )
                            .frame(width: 18, height: 18)

                            HDImage(
                                name: "ui_tb_speaker_2_24_regular",
                                template: true,
                                tint: p.text
                            )
                            .frame(width: 18, height: 18)

                            HDImage(
                                name: "ui_tb_battery_10_24",
                                template: true,
                                tint: p.text
                            )
                            .frame(width: 18, height: 18)
                        }
                        .padding(.horizontal, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: onToggleCalendar) {
                        HStack(spacing: 8) {
                            TimelineView(.periodic(from: .now, by: 30)) { context in
                                VStack(alignment: .trailing, spacing: -1) {
                                    Text(context.date, format: .dateTime.hour().minute())
                                    Text(context.date, format: .dateTime.day().month().year())
                                }
                                .font(.system(size: 10.5))
                            }

                            HDImage(
                                name: "ui_tb_alert_24_regular",
                                template: true,
                                tint: p.text
                            )
                            .frame(width: 18, height: 18)
                        }
                        .padding(.horizontal, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .foregroundColor(p.text)
            }
        }
        .frame(height: metrics.taskbarHeight)
        .padding(.horizontal, metrics.taskbarMarginHorizontal)
        .padding(.bottom, metrics.taskbarMarginBottom)
    }
}

private struct HDTaskbarIcon: View {
    let asset: String
    let size: CGFloat
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottom) {
                HDImage(name: asset)
                    .frame(width: size, height: size)
                    .padding(.horizontal, 8.6)
                    .frame(maxHeight: .infinity)

                if active {
                    Capsule()
                        .fill(Color(red: 0.0, green: 0.47, blue: 0.84))
                        .frame(width: 15, height: 3)
                        .padding(.bottom, 3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 2.5)
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
