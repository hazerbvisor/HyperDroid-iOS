import SwiftUI
import WebKit

struct BrowserWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.keyboardDismissMode = .interactive
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.085, alpha: 1)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
}

struct BrowserPane: View {
    @State private var address = "https://www.google.com"
    @State private var currentURL = URL(string: "https://www.google.com")!

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                BrowserToolbarButton("chevron.left")
                BrowserToolbarButton("chevron.right")
                BrowserToolbarButton("arrow.clockwise")

                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.55))

                    TextField("Search Google or type a URL", text: $address)
                        .font(.system(size: 11.5))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .onSubmit(loadAddress)

                    Button(action: loadAddress) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 15))

                BrowserToolbarButton("star")
                BrowserToolbarButton("ellipsis")
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 9)
            .frame(height: 42)
            .background(Color(red: 0.09, green: 0.09, blue: 0.095))

            BrowserWebView(url: currentURL)
                .id(currentURL)
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.085))
    }

    private func loadAddress() {
        var value = address.trimmingCharacters(in: .whitespacesAndNewlines)

        if !value.contains("://") {
            if value.contains(".") && !value.contains(" ") {
                value = "https://" + value
            } else {
                let query = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                value = "https://www.google.com/search?q=" + query
            }
        }

        if let url = URL(string: value) {
            address = value
            currentURL = url
        }
    }
}

struct BrowserToolbarButton: View {
    let symbol: String

    init(_ symbol: String) {
        self.symbol = symbol
    }

    var body: some View {
        Button(action: {}) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .medium))
                .frame(width: 27, height: 27)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
