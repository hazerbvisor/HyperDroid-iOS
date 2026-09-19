import SwiftUI
import WebKit
import UIKit

private enum HDBrowserDefaults {
    static let homeURL = URL(string: "https://www.google.com")!
    static let initialTabID = UUID()
}

private struct HDBrowserTab: Identifiable, Equatable {
    let id: UUID
    var title: String
    var url: URL

    init(id: UUID = UUID(), title: String = "New Tab", url: URL = HDBrowserDefaults.homeURL) {
        self.id = id
        self.title = title
        self.url = url
    }
}

private enum HDBrowserCommand: Equatable {
    case none
    case back
    case forward
    case reload
    case load(URL)
}

struct HDBrowserView: View {
    let onFocus: () -> Void
    let onMinimize: () -> Void
    let onClose: () -> Void
    let onMaximize: () -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: (CGSize) -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var tabs: [HDBrowserTab] = [
        HDBrowserTab(id: HDBrowserDefaults.initialTabID)
    ]
    @State private var selectedTabID = HDBrowserDefaults.initialTabID
    @State private var address = HDBrowserDefaults.homeURL.absoluteString
    @State private var dragStarted = false
    @State private var command: HDBrowserCommand = .none
    @State private var commandSerial = 0

    @AppStorage("hd.webAccess") private var webAccess = true
    @AppStorage("hd.defaultBrowser") private var defaultBrowser = "HyperDroid Browser"

    private var p: HDPalette { HDPalette(scheme: scheme) }

    var body: some View {
        VStack(spacing: 0) {
            titleAndTabs
            navigationBar

            if webAccess {
                browserPages
            } else {
                VStack(spacing: 10) {
                    Text("Network access is turned off")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(p.text)
                    Text("Enable Web access in Settings > Privacy & security.")
                        .font(.system(size: 13))
                        .foregroundColor(p.mutedText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(p.dialogBody)
            }
        }
        .background(p.dialogBody)
        .onChange(of: selectedURLString) { value in
            address = value
        }
    }

    private var titleAndTabs: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(tabs) { tab in
                        HStack(spacing: 7) {
                            HDImage(name: "img_app_chrome")
                                .frame(width: 15, height: 15)

                            Text(tab.title.isEmpty ? displayTitle(for: tab.url) : tab.title)
                                .font(.system(size: 11.5))
                                .foregroundColor(p.text)
                                .lineLimit(1)

                            Spacer(minLength: 2)

                            Button {
                                closeTab(tab.id)
                            } label: {
                                Text("×")
                                    .font(.system(size: 14))
                                    .foregroundColor(p.mutedText)
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.leading, 10)
                        .padding(.trailing, 5)
                        .frame(width: 160, height: 35)
                        .background(
                            selectedTabID == tab.id
                                ? p.dialogBody
                                : p.dialog.opacity(0.45)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectTab(tab.id)
                        }
                    }
                }
                .padding(.leading, 6)
            }
            .frame(maxWidth: 520)

            Button(action: addTab) {
                Text("+")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(p.text)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)

            Spacer(minLength: 0)

            browserWindowControl("app_title_ic_minimize_15", action: onMinimize)
            browserWindowControl("app_title_ic_resize_15", action: onMaximize)
            browserWindowControl("app_title_ic_close_16", danger: true, action: onClose)
        }
        .frame(height: 40)
        .background(p.dialog)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .global)
                .onChanged { value in
                    if !dragStarted {
                        dragStarted = true
                        onFocus()
                    }
                    onDragChanged(value.translation)
                }
                .onEnded { value in
                    onDragEnded(value.translation)
                    dragStarted = false
                }
        )
    }

    private var navigationBar: some View {
        HStack(spacing: 0) {
            browserNav("‹") { send(.back) }
            browserNav("›") { send(.forward) }
            browserNav("↻") { send(.reload) }

            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                    .foregroundColor(p.mutedText)

                TextField("Search Google or type a URL", text: $address)
                    .font(.system(size: 13))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit(loadAddress)
                    .foregroundColor(p.text)

                Button(action: {}) {
                    Image(systemName: "star")
                        .font(.system(size: 13))
                        .foregroundColor(p.mutedText)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(p.explorer)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(p.border.opacity(0.60), lineWidth: 1))
            .padding(.horizontal, 6)

            browserNav("↓", action: {})
            browserNav("⋮", action: {})
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 7)
        .background(p.dialogBody)
    }

    private var browserPages: some View {
        ZStack {
            ForEach(tabs) { tab in
                if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
                    HDWebView(
                        url: $tabs[index].url,
                        title: $tabs[index].title,
                        isActive: selectedTabID == tab.id,
                        command: command,
                        commandSerial: commandSerial,
                        onOpenNewTab: { url in
                            openTab(url)
                        }
                    )
                    .opacity(selectedTabID == tab.id ? 1 : 0)
                    .allowsHitTesting(selectedTabID == tab.id)
                    .accessibilityHidden(selectedTabID != tab.id)
                }
            }
        }
        .background(Color.white)
    }

    private var selectedURLString: String {
        tabs.first(where: { $0.id == selectedTabID })?.url.absoluteString
            ?? HDBrowserDefaults.homeURL.absoluteString
    }

    private func browserWindowControl(
        _ asset: String,
        danger: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HDImage(name: asset, template: true, tint: p.text)
                .frame(width: 15, height: 15)
                .frame(width: 52, height: 38)
        }
        .buttonStyle(.plain)
        .background(danger ? Color.red.opacity(0.001) : Color.clear)
    }

    private func browserNav(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18))
                .foregroundColor(p.text)
                .frame(width: 34, height: 32)
        }
        .buttonStyle(.plain)
    }

    private func addTab() {
        openTab(HDBrowserDefaults.homeURL)
    }

    private func openTab(_ url: URL) {
        let tab = HDBrowserTab(
            title: url == HDBrowserDefaults.homeURL ? "New Tab" : displayTitle(for: url),
            url: url
        )
        tabs.append(tab)
        selectedTabID = tab.id
        address = url.absoluteString
    }

    private func selectTab(_ id: UUID) {
        selectedTabID = id
        if let tab = tabs.first(where: { $0.id == id }) {
            address = tab.url.absoluteString
        }
    }

    private func closeTab(_ id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }

        if tabs.count == 1 {
            tabs[0].url = HDBrowserDefaults.homeURL
            tabs[0].title = "New Tab"
            selectedTabID = tabs[0].id
            address = HDBrowserDefaults.homeURL.absoluteString
            send(.load(HDBrowserDefaults.homeURL))
            return
        }

        let wasSelected = selectedTabID == id
        tabs.remove(at: index)

        if wasSelected {
            let newIndex = min(index, tabs.count - 1)
            selectedTabID = tabs[newIndex].id
            address = tabs[newIndex].url.absoluteString
        }
    }

    private func loadAddress() {
        var value = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.contains("://") {
            if value.contains(".") && !value.contains(" ") {
                value = "https://" + value
            } else {
                let q = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                value = "https://www.google.com/search?q=" + q
            }
        }

        guard let url = URL(string: value) else { return }

        if defaultBrowser == "External browser" {
            UIApplication.shared.open(url)
            return
        }

        guard let index = tabs.firstIndex(where: { $0.id == selectedTabID }) else { return }
        tabs[index].url = url
        address = url.absoluteString
        send(.load(url))
    }

    private func send(_ value: HDBrowserCommand) {
        command = value
        commandSerial += 1
    }

    private func displayTitle(for url: URL) -> String {
        if url == HDBrowserDefaults.homeURL { return "New Tab" }
        return url.host?.replacingOccurrences(of: "www.", with: "") ?? "Tab"
    }
}

private struct HDWebView: UIViewRepresentable {
    @Binding var url: URL
    @Binding var title: String

    let isActive: Bool
    let command: HDBrowserCommand
    let commandSerial: Int
    let onOpenNewTab: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences.preferredContentMode = .desktop
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.preferences.isElementFullscreenEnabled = true
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.keyboardDismissMode = .interactive
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.load(URLRequest(url: url))
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.parent = self

        if isActive && commandSerial != context.coordinator.lastCommandSerial {
            switch command {
            case .back:
                if uiView.canGoBack { uiView.goBack() }
            case .forward:
                if uiView.canGoForward { uiView.goForward() }
            case .reload:
                uiView.reload()
            case .load(let destination):
                uiView.load(URLRequest(url: destination))
            case .none:
                break
            }
            context.coordinator.lastCommandSerial = commandSerial
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: HDWebView
        var lastCommandSerial = 0

        init(_ parent: HDWebView) {
            self.parent = parent
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if let currentURL = navigationAction.request.url,
               parent.url != currentURL {
                parent.url = currentURL
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let currentURL = webView.url, parent.url != currentURL {
                parent.url = currentURL
            }

            let webTitle = webView.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !webTitle.isEmpty && parent.title != webTitle {
                parent.title = webTitle
            }
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil,
               let url = navigationAction.request.url {
                DispatchQueue.main.async {
                    self.parent.onOpenNewTab(url)
                }
            }
            return nil
        }
    }
}
