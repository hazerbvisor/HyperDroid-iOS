import SwiftUI

struct DesktopView: View {
    @StateObject private var controller = HDDesktopController()
    @State private var actionCenterVisible = false
    @State private var calendarVisible = false
    @State private var moreIconsVisible = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            let metrics = HDMetrics.forSize(geo.size)
            ZStack(alignment: .bottom) {
                Color.black.ignoresSafeArea()

                desktopIcons(geo.size, metrics)

                ForEach(controller.windows.sorted(by: { $0.z < $1.z })) { window in
                    HDWindowView(
                        state: window,
                        desktopSize: geo.size,
                        taskbarHeight: metrics.taskbarHeight,
                        active: controller.activeWindowID == window.id,
                        onFocus: { controller.focus(window.id) },
                        onClose: { controller.close(window.id) },
                        onMove: { controller.move(window.id, by: $0) },
                        onMaximize: { controller.toggleMaximize(window.id) }
                    )
                    .zIndex(Double(window.z))
                }

                if controller.startMenuVisible || actionCenterVisible || calendarVisible || moreIconsVisible {
                    Color.black.opacity(0.001)
                        .contentShape(Rectangle())
                        .onTapGesture { dismissPopups() }
                        .zIndex(8900)
                }

                if controller.startMenuVisible {
                    HDStartMenuView(metrics: metrics) { app in
                        open(app.kind, in: geo.size, metrics: metrics)
                    }
                    .padding(.bottom, metrics.startMarginBottom)
                    .zIndex(10000)
                }

                if moreIconsVisible {
                    HDMoreIconsPanelView {
                        dismissPopups()
                        open(.installer, in: geo.size, metrics: metrics)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 205)
                    .padding(.bottom, metrics.taskbarHeight + 6)
                    .zIndex(10020)
                }

                if actionCenterVisible {
                    HDActionCenterView {
                        dismissPopups()
                        open(.settings, in: geo.size, metrics: metrics)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 8)
                    .padding(.bottom, metrics.taskbarHeight + 6)
                    .zIndex(10030)
                }

                if calendarVisible {
                    HDCalendarPanelView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.trailing, 8)
                        .padding(.bottom, metrics.taskbarHeight + 6)
                        .zIndex(10030)
                }

                HDTaskbarView(
                    metrics: metrics,
                    windows: controller.windows,
                    activeWindowID: controller.activeWindowID,
                    startMenuVisible: controller.startMenuVisible,
                    onToggleStart: {
                        let next = !controller.startMenuVisible
                        dismissPopups()
                        controller.startMenuVisible = next
                    },
                    onOpen: { open($0, in: geo.size, metrics: metrics) },
                    onFocus: { controller.focus($0) },
                    onToggleMore: {
                        let next = !moreIconsVisible
                        dismissPopups()
                        moreIconsVisible = next
                    },
                    onToggleActionCenter: {
                        let next = !actionCenterVisible
                        dismissPopups()
                        actionCenterVisible = next
                    },
                    onToggleCalendar: {
                        let next = !calendarVisible
                        dismissPopups()
                        calendarVisible = next
                    }
                )
                .zIndex(20000)
            }
            .ignoresSafeArea()
        }
    }

    private func dismissPopups() {
        controller.startMenuVisible = false
        actionCenterVisible = false
        calendarVisible = false
        moreIconsVisible = false
    }

    @ViewBuilder
    private func desktopIcons(_ size: CGSize, _ metrics: HDMetrics) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                controller.open(.explorer, desktop: size, taskbarHeight: metrics.taskbarHeight)
            } label: {
                VStack(spacing: 0) {
                    HDImage(name: "img_app_explorer").frame(width: 46, height: 46)
                    Text("This PC")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .shadow(color: .black, radius: 2, x: 1, y: 2)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                }
                .padding(.top, 4)
                .frame(width: 90)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.bottom, metrics.taskbarHeight)
    }

    private func open(_ kind: HDAppEntry.Kind, in size: CGSize, metrics: HDMetrics) {
        let window: HDWindowKind
        switch kind {
        case .explorer: window = .explorer
        case .settings: window = .settings
        case .chrome: window = .chrome
        case .photos: window = .photos
        case .music: window = .music
        case .notepad: window = .notepad
        case .installer: window = .installer
        }
        controller.open(window, desktop: size, taskbarHeight: metrics.taskbarHeight)
    }
}

private struct HDWindowView: View {
    let state: HDWindowState
    let desktopSize: CGSize
    let taskbarHeight: CGFloat
    let active: Bool
    let onFocus: () -> Void
    let onClose: () -> Void
    let onMove: (CGSize) -> Void
    let onMaximize: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var drag: CGSize = .zero

    private var palette: HDPalette { HDPalette(scheme: scheme) }

    private var size: CGSize {
        state.maximized
        ? CGSize(width: desktopSize.width, height: desktopSize.height - taskbarHeight)
        : state.size
    }

    private var center: CGPoint {
        state.maximized
        ? CGPoint(x: desktopSize.width / 2, y: (desktopSize.height - taskbarHeight) / 2)
        : CGPoint(x: state.center.x + drag.width, y: state.center.y + drag.height)
    }

    var body: some View {
        VStack(spacing: 0) {
            if state.kind == .chrome {
                HDBrowserView(
                    onFocus: onFocus,
                    onClose: onClose,
                    onMaximize: onMaximize,
                    onMove: onMove
                )
            } else {
                titlebar
                Group {
                    switch state.kind {
                    case .explorer: HDExplorerView()
                    case .settings: HDSettingsView()
                    case .photos: HDPhotosView()
                    case .music: HDMusicView()
                    case .notepad: HDNotepadView()
                    case .installer: HDInstallerView()
                    case .chrome: EmptyView()
                    }
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .background(palette.dialog)
        .clipShape(RoundedRectangle(cornerRadius: state.maximized ? 0 : 3))
        .overlay(
            RoundedRectangle(cornerRadius: state.maximized ? 0 : 3)
                .stroke(palette.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(state.maximized ? 0 : 0.35), radius: 18, y: 7)
        .position(center)
        .onTapGesture(perform: onFocus)
    }

    private var titlebar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 12) {
                HDImage(name: state.kind.asset).frame(width: 18, height: 18)
                Text(state.kind.title)
                    .font(.system(size: 12))
                    .foregroundColor(palette.text)
                    .lineLimit(1)
            }
            .padding(.leading, 12)

            Spacer(minLength: 0)
            titleButton("app_title_ic_minimize_15", action: onFocus)
            titleButton("app_title_ic_resize_15", action: onMaximize)
            titleButton("app_title_ic_close_16", danger: true, action: onClose)
        }
        .frame(height: 38)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: state.maximized ? 10000 : 1)
                .onChanged { value in
                    onFocus()
                    drag = value.translation
                }
                .onEnded { value in
                    onMove(value.translation)
                    drag = .zero
                }
        )
    }

    private func titleButton(
        _ asset: String,
        danger: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HDImage(name: asset, template: true, tint: palette.text)
                .frame(width: 15, height: 15)
                .frame(width: 52, height: 38)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(danger ? Color.red.opacity(0.001) : Color.clear)
    }
}
