import SwiftUI

struct DesktopView: View {
    @StateObject private var controller = HDDesktopController()
    @State private var actionCenterVisible = false
    @State private var calendarVisible = false
    @State private var moreIconsVisible = false
    @State private var taskbarPeek = false
    @Environment(\.colorScheme) private var scheme
    @AppStorage("hd.theme") private var theme = "Dark"
    @AppStorage("hd.backgroundStyle") private var backgroundStyle = "Black"
    @AppStorage("hd.nightLight") private var nightLight = false
    @AppStorage("hd.taskbarAutoHide") private var taskbarAutoHide = false

    var body: some View {
        GeometryReader { geo in
            let metrics = HDMetrics.forSize(geo.size)
            let shouldHideTaskbar = taskbarAutoHide
                && controller.activeWindowID != nil
                && !taskbarPeek
                && !controller.startMenuVisible
                && !actionCenterVisible
                && !calendarVisible
                && !moreIconsVisible

            ZStack(alignment: .bottom) {
                desktopBackground.ignoresSafeArea()

                if nightLight {
                    Color.orange.opacity(0.08)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                desktopIcons(geo.size, metrics)

                ForEach(controller.windows.filter { !$0.minimized }.sorted(by: { $0.z < $1.z })) { window in
                    HDWindowView(
                        state: window,
                        desktopSize: geo.size,
                        taskbarHeight: metrics.taskbarHeight,
                        active: controller.activeWindowID == window.id,
                        onFocus: { controller.focus(window.id) },
                        onMinimize: { controller.minimize(window.id) },
                        onClose: { controller.close(window.id) },
                        onMove: {
                            controller.move(
                                window.id,
                                by: $0,
                                desktop: geo.size,
                                taskbarHeight: metrics.taskbarHeight
                            )
                        },
                        onMaximize: { controller.toggleMaximize(window.id) }
                    )
                    .zIndex(Double(window.z))
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.94).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .scale(scale: 0.86)).combined(with: .opacity)
                        )
                    )
                }

                if controller.startMenuVisible || actionCenterVisible || calendarVisible || moreIconsVisible {
                    Color.black.opacity(0.001)
                        .contentShape(Rectangle())
                        .onTapGesture { dismissPopups(animated: true) }
                        .zIndex(8900)
                }

                if controller.startMenuVisible {
                    HDStartMenuView(metrics: metrics) { app in
                        open(app.kind, in: geo.size, metrics: metrics)
                    }
                    .padding(.bottom, metrics.startMarginBottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10000)
                }

                if moreIconsVisible {
                    HDMoreIconsPanelView {
                        dismissPopups(animated: true)
                        open(.installer, in: geo.size, metrics: metrics)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 190)
                    .padding(.bottom, metrics.taskbarHeight + 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10020)
                }

                if actionCenterVisible {
                    HDActionCenterView {
                        dismissPopups(animated: true)
                        open(.settings, in: geo.size, metrics: metrics)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 8)
                    .padding(.bottom, metrics.taskbarHeight + 6)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(10030)
                }

                if calendarVisible {
                    HDCalendarPanelView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.trailing, 8)
                        .padding(.bottom, metrics.taskbarHeight + 6)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .zIndex(10030)
                }

                HDTaskbarView(
                    metrics: metrics,
                    windows: controller.windows,
                    activeWindowID: controller.activeWindowID,
                    startMenuVisible: controller.startMenuVisible,
                    onToggleStart: {
                        let next = !controller.startMenuVisible
                        dismissPopups(animated: false)
                        withAnimation(.spring(response: 0.26, dampingFraction: 0.88)) {
                            controller.startMenuVisible = next
                        }
                    },
                    onSearch: {
                        dismissPopups(animated: false)
                        withAnimation(.spring(response: 0.26, dampingFraction: 0.88)) {
                            controller.startMenuVisible = true
                        }
                    },
                    onOpen: { open($0, in: geo.size, metrics: metrics) },
                    onWindowAction: { controller.taskbarAction($0) },
                    onToggleMore: {
                        let next = !moreIconsVisible
                        dismissPopups(animated: false)
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.90)) {
                            moreIconsVisible = next
                        }
                    },
                    onToggleActionCenter: {
                        let next = !actionCenterVisible
                        dismissPopups(animated: false)
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.90)) {
                            actionCenterVisible = next
                        }
                    },
                    onToggleCalendar: {
                        let next = !calendarVisible
                        dismissPopups(animated: false)
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.90)) {
                            calendarVisible = next
                        }
                    }
                )
                .offset(y: shouldHideTaskbar ? metrics.taskbarHeight - 3 : 0)
                .animation(.easeOut(duration: 0.18), value: shouldHideTaskbar)
                .zIndex(20000)

                if shouldHideTaskbar {
                    Color.clear
                        .frame(height: 14)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.16)) {
                                taskbarPeek = true
                            }
                        }
                        .zIndex(21000)
                }
            }
            .ignoresSafeArea()
        }
        .preferredColorScheme(preferredScheme)
    }

    private var preferredScheme: ColorScheme? {
        switch theme {
        case "Light": return .light
        case "System": return nil
        default: return .dark
        }
    }

    @ViewBuilder
    private var desktopBackground: some View {
        switch backgroundStyle {
        case "Windows Blue":
            Color(red: 0.02, green: 0.20, blue: 0.42)
        case "Gradient":
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.08, blue: 0.18),
                    Color(red: 0.03, green: 0.34, blue: 0.58)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            Color.black
        }
    }

    private func dismissPopups(animated: Bool) {
        let changes = {
            controller.startMenuVisible = false
            actionCenterVisible = false
            calendarVisible = false
            moreIconsVisible = false
        }

        if animated {
            withAnimation(.easeOut(duration: 0.16), changes)
        } else {
            changes()
        }
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
    let onMinimize: () -> Void
    let onClose: () -> Void
    let onMove: (CGSize) -> Void
    let onMaximize: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var drag: CGSize = .zero
    @State private var dragStarted = false

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
                    onMinimize: onMinimize,
                    onClose: onClose,
                    onMaximize: onMaximize,
                    onDragChanged: { value in
                        if !state.maximized {
                            drag = value
                        }
                    },
                    onDragEnded: { value in
                        if !state.maximized {
                            onMove(value)
                        }
                        drag = .zero
                    }
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
        .clipShape(RoundedRectangle(cornerRadius: state.maximized ? 0 : 4))
        .overlay(
            RoundedRectangle(cornerRadius: state.maximized ? 0 : 4)
                .stroke(active ? palette.border.opacity(0.95) : palette.border.opacity(0.65), lineWidth: 1)
        )
        .shadow(color: .black.opacity(state.maximized ? 0 : (active ? 0.38 : 0.24)), radius: active ? 18 : 12, y: 7)
        .position(center)
        .animation(.spring(response: 0.32, dampingFraction: 0.90), value: state.maximized)
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

            titleButton("app_title_ic_minimize_15", action: onMinimize)
            titleButton("app_title_ic_resize_15", action: onMaximize)
            titleButton("app_title_ic_close_16", danger: true, action: onClose)
        }
        .frame(height: 38)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: state.maximized ? 10000 : 1, coordinateSpace: .global)
                .onChanged { value in
                    if !dragStarted {
                        dragStarted = true
                        onFocus()
                    }
                    drag = value.translation
                }
                .onEnded { value in
                    onMove(value.translation)
                    drag = .zero
                    dragStarted = false
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
