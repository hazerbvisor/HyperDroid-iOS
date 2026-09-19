import SwiftUI
import Foundation

// MARK: - Window model

enum HyperWindowKind: String, CaseIterable {
    case files
    case browser
    case settings

    var title: String {
        switch self {
        case .files: return "This PC"
        case .browser: return "UiChrome"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .files: return "folder.fill"
        case .browser: return "globe"
        case .settings: return "gearshape.fill"
        }
    }
}

struct HyperWindow: Identifiable, Equatable {
    let id: UUID
    let kind: HyperWindowKind
    var position: CGPoint
    var size: CGSize
    var zIndex: Int
    var maximized: Bool

    init(kind: HyperWindowKind, position: CGPoint, size: CGSize, zIndex: Int) {
        self.id = UUID()
        self.kind = kind
        self.position = position
        self.size = size
        self.zIndex = zIndex
        self.maximized = false
    }
}

@MainActor
final class DesktopModel: ObservableObject {
    @Published var windows: [HyperWindow] = []
    @Published var activeWindowID: UUID?
    @Published var startMenuPresented = false
    @Published var quickSettingsPresented = false

    private var nextZIndex = 1

    func open(_ kind: HyperWindowKind, in desktopSize: CGSize) {
        if let existing = windows.first(where: { $0.kind == kind }) {
            focus(existing.id)
            startMenuPresented = false
            return
        }

        let baseWidth: CGFloat
        let baseHeight: CGFloat

        switch kind {
        case .files:
            baseWidth = min(850, desktopSize.width * 0.82)
            baseHeight = min(600, desktopSize.height * 0.76)
        case .settings:
            baseWidth = min(760, desktopSize.width * 0.74)
            baseHeight = min(600, desktopSize.height * 0.76)
        case .browser:
            baseWidth = min(860, desktopSize.width * 0.82)
            baseHeight = min(610, desktopSize.height * 0.78)
        }

        let stagger = CGFloat(windows.count % 4) * 20
        let window = HyperWindow(
            kind: kind,
            position: CGPoint(
                x: desktopSize.width / 2 + stagger,
                y: (desktopSize.height - 52) / 2 + stagger * 0.45
            ),
            size: CGSize(width: max(520, baseWidth), height: max(380, baseHeight)),
            zIndex: nextZIndex
        )

        nextZIndex += 1
        windows.append(window)
        activeWindowID = window.id
        startMenuPresented = false
        quickSettingsPresented = false
    }

    func focus(_ id: UUID) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[index].zIndex = nextZIndex
        nextZIndex += 1
        activeWindowID = id
        quickSettingsPresented = false
    }

    func close(_ id: UUID) {
        windows.removeAll { $0.id == id }
        activeWindowID = windows.max(by: { $0.zIndex < $1.zIndex })?.id
    }

    func move(_ id: UUID, to position: CGPoint) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[index].position = position
    }

    func resize(_ id: UUID, to size: CGSize) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[index].size = CGSize(
            width: max(480, size.width),
            height: max(330, size.height)
        )
    }

    func toggleMaximize(_ id: UUID, desktopSize: CGSize) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[index].maximized.toggle()
        focus(id)
    }
}

// MARK: - Desktop

struct DesktopView: View {
    @StateObject private var model = DesktopModel()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Windows11Wallpaper()

                DesktopShortcuts {
                    model.open(.files, in: geometry.size)
                }

                ForEach(model.windows.sorted(by: { $0.zIndex < $1.zIndex })) { window in
                    DesktopWindowView(
                        window: window,
                        desktopSize: geometry.size,
                        isActive: model.activeWindowID == window.id,
                        onFocus: { model.focus(window.id) },
                        onClose: { model.close(window.id) },
                        onMove: { model.move(window.id, to: $0) },
                        onResize: { model.resize(window.id, to: $0) },
                        onMaximize: { model.toggleMaximize(window.id, desktopSize: geometry.size) }
                    )
                    .zIndex(Double(window.zIndex))
                }

                if model.startMenuPresented || model.quickSettingsPresented {
                    Color.black.opacity(0.001)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.12)) {
                                model.startMenuPresented = false
                                model.quickSettingsPresented = false
                            }
                        }
                        .zIndex(9000)
                }

                if model.startMenuPresented {
                    HyperStartMenu(
                        onOpen: { model.open($0, in: geometry.size) },
                        onPower: { model.startMenuPresented = false }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10000)
                }

                if model.quickSettingsPresented {
                    QuickSettingsPanel()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10000)
                }

                VStack(spacing: 0) {
                    Spacer()
                    HyperTaskbar(
                        windows: model.windows,
                        activeWindowID: model.activeWindowID,
                        startPresented: model.startMenuPresented,
                        onStart: {
                            withAnimation(.easeOut(duration: 0.14)) {
                                model.startMenuPresented.toggle()
                                model.quickSettingsPresented = false
                            }
                        },
                        onOpen: { model.open($0, in: geometry.size) },
                        onWindowTap: { model.focus($0) },
                        onTray: {
                            withAnimation(.easeOut(duration: 0.14)) {
                                model.quickSettingsPresented.toggle()
                                model.startMenuPresented = false
                            }
                        }
                    )
                }
                .zIndex(20000)
            }
            .ignoresSafeArea()
        }
    }
}

struct Windows11Wallpaper: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.025, green: 0.13, blue: 0.34),
                        Color(red: 0.018, green: 0.28, blue: 0.54),
                        Color(red: 0.04, green: 0.10, blue: 0.28)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.9), Color.blue.opacity(0.45)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: geo.size.width * 0.55, height: geo.size.height * 0.50)
                    .rotationEffect(.degrees(-22))
                    .offset(x: geo.size.width * 0.12, y: geo.size.height * 0.10)
                    .blur(radius: 3)

                Ellipse()
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.95), Color.purple.opacity(0.75), Color.pink.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: max(50, geo.size.width * 0.09)
                    )
                    .frame(width: geo.size.width * 0.53, height: geo.size.height * 0.64)
                    .rotationEffect(.degrees(24))
                    .offset(x: geo.size.width * 0.26, y: geo.size.height * 0.10)
                    .blur(radius: 2)

                LinearGradient(
                    colors: [Color.white.opacity(0.12), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
            }
        }
    }
}

struct DesktopShortcuts: View {
    let openFiles: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button(action: openFiles) {
                VStack(spacing: 5) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan, Color.blue],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 39, height: 29)

                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.22))
                            .frame(width: 32, height: 2)
                            .offset(y: 11)
                    }

                    Text("This PC")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2)
                }
                .frame(width: 76)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.top, 24)
        .padding(.leading, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Windows

struct DesktopWindowView: View {
    let window: HyperWindow
    let desktopSize: CGSize
    let isActive: Bool
    let onFocus: () -> Void
    let onClose: () -> Void
    let onMove: (CGPoint) -> Void
    let onResize: (CGSize) -> Void
    let onMaximize: () -> Void

    @State private var dragTranslation: CGSize = .zero
    @State private var resizeTranslation: CGSize = .zero

    private var effectiveSize: CGSize {
        if window.maximized {
            return CGSize(width: desktopSize.width, height: max(320, desktopSize.height - 49))
        }
        return CGSize(
            width: window.size.width + resizeTranslation.width,
            height: window.size.height + resizeTranslation.height
        )
    }

    private var effectivePosition: CGPoint {
        if window.maximized {
            return CGPoint(x: desktopSize.width / 2, y: max(160, (desktopSize.height - 49) / 2))
        }
        return CGPoint(
            x: window.position.x + dragTranslation.width,
            y: window.position.y + dragTranslation.height
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            windowTitleBar
            windowContent
        }
        .frame(width: effectiveSize.width, height: effectiveSize.height)
        .background(Color(red: 0.075, green: 0.075, blue: 0.082))
        .clipShape(RoundedRectangle(cornerRadius: window.maximized ? 0 : 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: window.maximized ? 0 : 8, style: .continuous)
                .stroke(Color.white.opacity(isActive ? 0.18 : 0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(window.maximized ? 0 : 0.5), radius: 18, y: 8)
        .overlay(alignment: .bottomTrailing) {
            if !window.maximized {
                resizeHandle
            }
        }
        .position(effectivePosition)
        .onTapGesture(perform: onFocus)
    }

    private var windowTitleBar: some View {
        HStack(spacing: 9) {
            Image(systemName: window.kind.symbol)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))

            Text(window.kind.title)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundColor(.white.opacity(0.92))

            Spacer()

            WindowControlButton(symbol: "minus", action: onFocus)
            WindowControlButton(symbol: "square", action: onMaximize)
            WindowControlButton(symbol: "xmark", destructive: true, action: onClose)
        }
        .padding(.leading, 12)
        .frame(height: 36)
        .background(Color(red: 0.105, green: 0.105, blue: 0.112))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: window.maximized ? 10000 : 1)
                .onChanged { value in
                    onFocus()
                    dragTranslation = value.translation
                }
                .onEnded { value in
                    onMove(
                        CGPoint(
                            x: window.position.x + value.translation.width,
                            y: window.position.y + value.translation.height
                        )
                    )
                    dragTranslation = .zero
                }
        )
    }

    @ViewBuilder
    private var windowContent: some View {
        switch window.kind {
        case .files:
            FileExplorerPane()
        case .browser:
            BrowserPane()
        case .settings:
            SettingsPane()
        }
    }

    private var resizeHandle: some View {
        Color.white.opacity(0.001)
            .frame(width: 26, height: 26)
            .overlay(alignment: .bottomTrailing) {
                Path { path in
                    path.move(to: CGPoint(x: 10, y: 24))
                    path.addLine(to: CGPoint(x: 24, y: 10))
                    path.move(to: CGPoint(x: 16, y: 24))
                    path.addLine(to: CGPoint(x: 24, y: 16))
                }
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        resizeTranslation = CGSize(
                            width: max(480 - window.size.width, value.translation.width),
                            height: max(330 - window.size.height, value.translation.height)
                        )
                    }
                    .onEnded { value in
                        onResize(
                            CGSize(
                                width: window.size.width + value.translation.width,
                                height: window.size.height + value.translation.height
                            )
                        )
                        resizeTranslation = .zero
                    }
            )
    }
}

struct WindowControlButton: View {
    let symbol: String
    var destructive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 44, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(destructive ? Color.red.opacity(0.001) : Color.clear)
    }
}

// MARK: - Taskbar + Start menu

struct HyperTaskbar: View {
    let windows: [HyperWindow]
    let activeWindowID: UUID?
    let startPresented: Bool
    let onStart: () -> Void
    let onOpen: (HyperWindowKind) -> Void
    let onWindowTap: (UUID) -> Void
    let onTray: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)

            Rectangle()
                .fill(Color(red: 0.09, green: 0.10, blue: 0.12).opacity(0.72))

            HStack(spacing: 0) {
                Button(action: { onOpen(.files) }) {
                    WindowsLogo()
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)

                Spacer()

                HStack(spacing: 4) {
                    TaskbarSquare(selected: startPresented, action: onStart) {
                        WindowsLogo()
                    }

                    Button(action: onStart) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Search")
                                .font(.system(size: 13))
                            Spacer(minLength: 2)
                        }
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 11)
                        .frame(width: 142, height: 34)
                        .background(Color.white.opacity(0.085))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    TaskbarAppButton(
                        kind: .browser,
                        symbol: "globe",
                        windows: windows,
                        activeWindowID: activeWindowID,
                        onOpen: onOpen,
                        onWindowTap: onWindowTap
                    )

                    TaskbarAppButton(
                        kind: .files,
                        symbol: "folder.fill",
                        windows: windows,
                        activeWindowID: activeWindowID,
                        onOpen: onOpen,
                        onWindowTap: onWindowTap
                    )

                    TaskbarAppButton(
                        kind: .settings,
                        symbol: "gearshape.fill",
                        windows: windows,
                        activeWindowID: activeWindowID,
                        onOpen: onOpen,
                        onWindowTap: onWindowTap
                    )
                }

                Spacer()

                Button(action: onTray) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 9, weight: .bold))
                        Image(systemName: "wifi")
                            .font(.system(size: 12))
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 12))
                        Image(systemName: "battery.75percent")
                            .font(.system(size: 15))

                        VStack(alignment: .trailing, spacing: 0) {
                            Text(Date.now, format: .dateTime.hour().minute())
                                .font(.system(size: 10.5))
                            Text(Date.now, format: .dateTime.day().month().year())
                                .font(.system(size: 9.5))
                        }

                        Image(systemName: "bell")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.92))
                    .padding(.horizontal, 10)
                    .frame(height: 42)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 48)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.09))
                .frame(height: 1)
        }
    }
}

struct TaskbarAppButton: View {
    let kind: HyperWindowKind
    let symbol: String
    let windows: [HyperWindow]
    let activeWindowID: UUID?
    let onOpen: (HyperWindowKind) -> Void
    let onWindowTap: (UUID) -> Void

    var body: some View {
        let matching = windows.first(where: { $0.kind == kind })
        let selected = matching?.id == activeWindowID

        TaskbarSquare(selected: selected) {
            if let matching {
                onWindowTap(matching.id)
            } else {
                onOpen(kind)
            }
        } content: {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(kind == .files ? .yellow : .white.opacity(0.95))
        }
    }
}

struct TaskbarSquare<Content: View>: View {
    let selected: Bool
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button(action: action) {
            content()
                .frame(width: 38, height: 38)
                .background(selected ? Color.white.opacity(0.10) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(alignment: .bottom) {
                    if selected {
                        Capsule()
                            .fill(Color.cyan)
                            .frame(width: 16, height: 2)
                            .offset(y: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

struct WindowsLogo: View {
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Rectangle().fill(Color(red: 0.0, green: 0.69, blue: 0.95))
                Rectangle().fill(Color(red: 0.0, green: 0.69, blue: 0.95))
            }
            HStack(spacing: 2) {
                Rectangle().fill(Color(red: 0.0, green: 0.69, blue: 0.95))
                Rectangle().fill(Color(red: 0.0, green: 0.69, blue: 0.95))
            }
        }
        .frame(width: 18, height: 18)
    }
}

struct HyperStartMenu: View {
    let onOpen: (HyperWindowKind) -> Void
    let onPower: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 17) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.78))
                    Text("Type here to search")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.72))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )

                HStack {
                    Text("Apps")
                        .font(.system(size: 12.5, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 10))
                        .frame(width: 38, height: 24)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }

                LazyVGrid(columns: columns, spacing: 15) {
                    StartMenuApp("Camera", "camera.fill", Color.gray) {}
                    StartMenuApp("Chrome", "globe", Color(red: 0.24, green: 0.55, blue: 0.96)) { onOpen(.browser) }
                    StartMenuApp("Clock", "clock.fill", Color.black) {}
                    StartMenuApp("Settings", "gearshape.fill", Color.gray) { onOpen(.settings) }
                    StartMenuApp("Themes", "paintpalette.fill", Color.purple) { onOpen(.settings) }
                    StartMenuApp("Play Store", "play.fill", Color.white, darkGlyph: true) {}

                    StartMenuApp("Gmail", "envelope.fill", Color.white, darkGlyph: true) {}
                    StartMenuApp("YouTube", "play.rectangle.fill", Color.red) { onOpen(.browser) }
                    StartMenuApp("File Manager", "folder.fill", Color.yellow) { onOpen(.files) }
                    StartMenuApp("Gallery", "photo.fill", Color.indigo) {}
                    StartMenuApp("Services & f...", "questionmark.app.fill", Color.cyan) {}
                    StartMenuApp("Calendar", "calendar", Color.white, darkGlyph: true) {}

                    StartMenuApp("Recorder", "waveform", Color(red: 0.2, green: 0.16, blue: 0.14)) {}
                    StartMenuApp("Outlook", "envelope.badge.fill", Color.blue) {}
                    StartMenuApp("Calculator", "plus.forwardslash.minus", Color.orange) {}
                    StartMenuApp("Notes", "note.text", Color.orange) {}
                    StartMenuApp("Weather", "cloud.sun.fill", Color.blue) {}
                    StartMenuApp("Nova Launc...", "app.badge.fill", Color.cyan) {}
                }

                Spacer(minLength: 4)

                Text("Recommended")
                    .font(.system(size: 12.5, weight: .semibold))

                Text("The more you use your device, we will show you new apps here.")
                    .font(.system(size: 11.5))
                    .foregroundColor(.white.opacity(0.58))

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 38)
            .padding(.top, 18)

            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 23))
                    Text("This PC")
                        .font(.system(size: 12.5, weight: .medium))
                }

                Spacer()

                Button(action: onPower) {
                    Image(systemName: "power")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 38)
            .frame(height: 55)
            .background(Color.black.opacity(0.20))
        }
        .foregroundColor(.white)
        .frame(width: 500, height: 500)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .background(Color(red: 0.10, green: 0.12, blue: 0.14).opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 54)
    }
}

struct StartMenuApp: View {
    let name: String
    let symbol: String
    let color: Color
    let darkGlyph: Bool
    let action: () -> Void

    init(_ name: String, _ symbol: String, _ color: Color, darkGlyph: Bool = false, action: @escaping () -> Void) {
        self.name = name
        self.symbol = symbol
        self.color = color
        self.darkGlyph = darkGlyph
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(color.opacity(darkGlyph ? 0.96 : 0.88))
                        .frame(width: 30, height: 30)

                    Image(systemName: symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(darkGlyph ? .black.opacity(0.75) : .white)
                }

                Text(name)
                    .font(.system(size: 9.5))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick settings

struct QuickSettingsPanel: View {
    @State private var volume = 0.62
    @State private var wifi = true
    @State private var bluetooth = true
    @State private var darkTheme = true

    var body: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickToggle("Wi-Fi", "wifi", $wifi)
                QuickToggle("Internet", "network", .constant(true))
                QuickToggle("Bluetooth", "bluetooth", $bluetooth)
                QuickToggle("Nearby", "dot.radiowaves.left.and.right", .constant(false))
                QuickToggle("Theme", "moon.fill", $darkTheme)
                QuickToggle("Access", "figure.wave", .constant(false))
            }

            HStack(spacing: 12) {
                Image(systemName: "speaker.wave.2.fill")
                Slider(value: $volume)
            }

            HStack {
                Text("93%")
                    .font(.system(size: 12))
                Image(systemName: "battery.100percent")
                Spacer()
                Text(Date.now, format: .dateTime.hour().minute())
                    .font(.system(size: 12, weight: .medium))
            }
        }
        .padding(18)
        .frame(width: 340)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .background(Color(red: 0.12, green: 0.13, blue: 0.15).opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.45), radius: 24, y: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.trailing, 8)
        .padding(.bottom, 55)
    }
}

struct QuickToggle: View {
    let title: String
    let symbol: String
    @Binding var isOn: Bool

    init(_ title: String, _ symbol: String, _ isOn: Binding<Bool>) {
        self.title = title
        self.symbol = symbol
        self._isOn = isOn
    }

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            VStack(spacing: 7) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 52, height: 34)
                    .background(isOn ? Color(red: 0.0, green: 0.47, blue: 0.84) : Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                Text(title)
                    .font(.system(size: 10))
            }
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - File Explorer

struct FileExplorerPane: View {
    @State private var entries: [URL] = []

    private let folders: [(String, String, Color)] = [
        ("Documents", "doc.fill", .cyan),
        ("Downloads", "arrow.down.square.fill", .mint),
        ("Music", "music.note", .pink),
        ("Pictures", "photo.fill", .blue),
        ("Videos", "play.rectangle.fill", .purple)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.left")
                Image(systemName: "arrow.right")
                    .foregroundColor(.white.opacity(0.35))
                Image(systemName: "arrow.up")
                HStack {
                    Image(systemName: "desktopcomputer")
                    Text("This PC")
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9))
                }
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(Color.white.opacity(0.06))
                .overlay(Rectangle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                Spacer()
            }
            .font(.system(size: 12))
            .padding(.horizontal, 10)
            .frame(height: 42)
            .background(Color(red: 0.09, green: 0.09, blue: 0.095))

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    ExplorerSideRow("This PC", "desktopcomputer", selected: true)
                    ExplorerSideRow("Documents", "doc.fill")
                    ExplorerSideRow("Downloads", "arrow.down.circle.fill")
                    ExplorerSideRow("Music", "music.note")
                    Divider().opacity(0.18)
                    ExplorerSideRow("Pictures", "photo.fill")
                    ExplorerSideRow("Videos", "play.rectangle.fill")
                    ExplorerSideRow("Internal (C:)", "externaldrive.fill")
                    Spacer()
                }
                .padding(.vertical, 10)
                .frame(width: 165, alignment: .topLeading)
                .background(Color.black.opacity(0.15))

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Folders (5)")
                            .font(.system(size: 12.5, weight: .semibold))

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 165), spacing: 12)], spacing: 12) {
                            ForEach(folders, id: \.0) { item in
                                HStack(spacing: 12) {
                                    Image(systemName: item.1)
                                        .font(.system(size: 27))
                                        .foregroundColor(item.2)
                                        .frame(width: 36)

                                    Text(item.0)
                                        .font(.system(size: 12))
                                    Spacer()
                                }
                                .padding(.horizontal, 9)
                                .frame(height: 48)
                            }
                        }

                        Text("Devices and drives")
                            .font(.system(size: 12.5, weight: .semibold))
                            .padding(.top, 6)

                        HStack(spacing: 12) {
                            Image(systemName: "internaldrive.fill")
                                .font(.system(size: 27))
                                .foregroundColor(.gray)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Internal (C:)")
                                    .font(.system(size: 12))
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Rectangle().fill(Color.white.opacity(0.8))
                                        Rectangle().fill(Color(red: 0.0, green: 0.55, blue: 0.85))
                                            .frame(width: geo.size.width * 0.65)
                                    }
                                }
                                .frame(width: 150, height: 8)

                                Text("23.7 GB free of 64.0 GB")
                                    .font(.system(size: 9.5))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                        }

                        if !entries.isEmpty {
                            Divider().opacity(0.18)
                            Text("HyperDroid Documents")
                                .font(.system(size: 12.5, weight: .semibold))

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)]) {
                                ForEach(entries, id: \.path) { url in
                                    HStack(spacing: 8) {
                                        Image(systemName: url.hasDirectoryPath ? "folder.fill" : "doc.fill")
                                            .foregroundColor(url.hasDirectoryPath ? .yellow : .white.opacity(0.75))
                                        Text(url.lastPathComponent)
                                            .font(.system(size: 10.5))
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(7)
                                    .background(Color.white.opacity(0.04))
                                }
                            }
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(14)
                }
            }
        }
        .foregroundColor(.white.opacity(0.94))
        .background(Color(red: 0.055, green: 0.055, blue: 0.06))
        .onAppear(perform: refresh)
    }

    private func refresh() {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            entries = []
            return
        }
        entries = (try? FileManager.default.contentsOfDirectory(
            at: documents,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []
    }
}

struct ExplorerSideRow: View {
    let title: String
    let symbol: String
    var selected = false

    init(_ title: String, _ symbol: String, selected: Bool = false) {
        self.title = title
        self.symbol = symbol
        self.selected = selected
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .frame(width: 18)
                .foregroundColor(selected ? .cyan : .white.opacity(0.8))
            Text(title)
                .font(.system(size: 11.5))
            Spacer()
        }
        .padding(.horizontal, 9)
        .frame(height: 29)
        .background(selected ? Color.white.opacity(0.08) : Color.clear)
    }
}

// MARK: - Settings

struct SettingsPane: View {
    @State private var selection = "Personalize"

    private let nav: [(String, String)] = [
        ("System", "display"),
        ("Bluetooth & devices", "link"),
        ("Personalize", "paintbrush.fill"),
        ("Apps", "square.grid.2x2.fill"),
        ("Accounts", "person.fill"),
        ("Time & language", "clock.fill"),
        ("Privacy & security", "shield.fill"),
        ("PC Update", "arrow.triangle.2.circlepath")
    ]

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13))
                    Text("Settings")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.bottom, 6)

                HStack(spacing: 10) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 36))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("This PC")
                            .font(.system(size: 12, weight: .medium))
                        Text("Local Account")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }
                .padding(.vertical, 8)

                ForEach(nav, id: \.0) { item in
                    Button {
                        selection = item.0
                    } label: {
                        HStack(spacing: 9) {
                            Image(systemName: item.1)
                                .frame(width: 17)
                                .foregroundColor(item.0 == "Personalize" ? .cyan : .white.opacity(0.78))
                            Text(item.0)
                                .font(.system(size: 11.5))
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .frame(height: 31)
                        .background(selection == item.0 ? Color.white.opacity(0.08) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(13)
            .frame(width: 190, alignment: .topLeading)
            .background(Color.black.opacity(0.12))

            ScrollView {
                if selection == "Personalize" {
                    PersonalizeSettings()
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(selection)
                            .font(.system(size: 23, weight: .semibold))
                        SettingsCard(title: "HyperDroid iOS", subtitle: "This section will be connected to the iOS equivalent where possible.", symbol: "info.circle")
                        Spacer()
                    }
                    .padding(20)
                }
            }
        }
        .foregroundColor(.white.opacity(0.95))
        .background(Color(red: 0.08, green: 0.08, blue: 0.085))
    }
}

struct PersonalizeSettings: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personalize")
                .font(.system(size: 23, weight: .semibold))

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black)
                Windows11Wallpaper()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(5)
            }
            .frame(width: 178, height: 102)

            SettingsCard(title: "Background", subtitle: "Background image, color, slideshow", symbol: "photo")
            SettingsCard(title: "Colors", subtitle: "Accent color, transparency effects, color theme", symbol: "paintpalette")
            SettingsCard(title: "Start", subtitle: "Config StartMenu pattern and layout", symbol: "square.grid.2x2")
            SettingsCard(title: "Taskbar", subtitle: "Taskbar behaviours, system pins", symbol: "rectangle.inset.filled")

            Spacer(minLength: 20)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsCard: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 17))
                .frame(width: 25)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 9.5))
                    .foregroundColor(.white.opacity(0.55))
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 54)
        .background(Color.white.opacity(0.075))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
