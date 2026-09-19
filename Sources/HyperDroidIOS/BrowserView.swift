import SwiftUI
import WebKit

struct HDBrowserView: View {
    let onFocus: () -> Void
    let onClose: () -> Void
    let onMaximize: () -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: (CGSize) -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var address = "https://www.google.com"
    @State private var currentURL = URL(string: "https://www.google.com")!
    @State private var dragStarted = false
    private var p: HDPalette { HDPalette(scheme: scheme) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        HStack(spacing: 8) {
                            HDImage(name: "img_app_chrome").frame(width: 16, height: 16)
                            Text("New Tab").font(.system(size: 12)).foregroundColor(p.text).lineLimit(1)
                            Spacer(minLength: 4)
                            Text("×").font(.system(size: 15)).foregroundColor(p.mutedText)
                        }
                        .padding(.horizontal, 10)
                        .frame(width: 180, height: 40)
                        .background(p.dialogBody)
                    }
                }
                .frame(maxWidth: 260)

                Button(action: {}) {
                    Text("+").font(.system(size: 20, weight: .light)).foregroundColor(p.text)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .padding(.leading, 6)

                Spacer(minLength: 0)
                browserWindowControl("app_title_ic_minimize_15", action: onFocus)
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

            HStack(spacing: 0) {
                browserNav("‹", action: {})
                browserNav("›", action: {})
                browserNav("↻", action: reload)

                HStack(spacing: 8) {
                    Text("G").font(.system(size: 14, weight: .semibold)).foregroundColor(.blue)
                    TextField("Search Google or type a URL", text: $address)
                        .font(.system(size: 14))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .onSubmit(loadAddress)
                        .foregroundColor(p.text)
                    Button(action: {}) {
                        HDImage(name: "img_app_installer").frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background(p.explorer)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(p.border.opacity(0.65), lineWidth: 1))
                .padding(.horizontal, 6)

                browserNav("↓", action: {})
                browserNav("⋮", action: {})
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background(p.dialogBody)

            HDWebView(url: currentURL)
                .id(currentURL)
        }
        .background(p.dialogBody)
    }

    private func browserWindowControl(_ asset: String, danger: Bool = false, action: @escaping () -> Void) -> some View {
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
            Text(label).font(.system(size: 18)).foregroundColor(p.text).frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
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
        if let url = URL(string: value) {
            currentURL = url
            address = value
        }
    }

    private func reload() {
        currentURL = URL(string: currentURL.absoluteString + (currentURL.query == nil ? "?" : "&") + "_hdreload=1") ?? currentURL
    }
}

struct HDWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let view = WKWebView(frame: .zero, configuration: config)
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.keyboardDismissMode = .interactive
        view.load(URLRequest(url: url))
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url?.absoluteString != url.absoluteString {
            uiView.load(URLRequest(url: url))
        }
    }
}
