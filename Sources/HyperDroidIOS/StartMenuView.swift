import SwiftUI

struct HDStartMenuView: View {
    let metrics: HDMetrics
    let onOpen: (HDAppEntry) -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var search = ""
    @FocusState private var searchFocused: Bool

    @AppStorage("hd.taskbarAlignment") private var taskbarAlignment = "Center"
    @AppStorage("hd.startShowSearch") private var showSearch = true
    @AppStorage("hd.startShowRecommended") private var showRecommended = true
    @AppStorage("hd.startCompact") private var compact = false
    @AppStorage("hd.startColumns") private var startColumns = "Default"
    @AppStorage("hd.startSearchFocus") private var startSearchFocus = false
    @AppStorage("hd.accountName") private var accountName = "Name"
    @AppStorage("hd.transparency") private var transparency = true

    private var p: HDPalette { HDPalette(scheme: scheme) }

    private var filtered: [HDAppEntry] {
        search.isEmpty
            ? HDAppEntry.builtIns
            : HDAppEntry.builtIns.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }

    private var columnCount: Int {
        if taskbarAlignment == "Center" {
            switch startColumns {
            case "4 columns": return 4
            case "6 columns": return 6
            default: return 6
            }
        }

        switch startColumns {
        case "4 columns": return 4
        case "6 columns": return 6
        default: return metrics.landscape ? 6 : 4
        }
    }

    var body: some View {
        GeometryReader { geo in
            let centered = taskbarAlignment == "Center"
            let panelWidth = centered
                ? min(642, geo.size.width - 32)
                : min(560, geo.size.width - 24)

            let maxPanelHeight = max(
                420,
                geo.size.height - metrics.taskbarHeight - (centered ? 24 : 18)
            )
            let regularHeight = centered ? min(724, maxPanelHeight) : min(620, maxPanelHeight)
            let panelHeight = compact ? max(420, regularHeight - 120) : regularHeight

            VStack(spacing: 0) {
                if showSearch {
                    searchHeader(centered: centered)
                }

                pinnedSection(centered: centered)

                if showRecommended && !compact {
                    recommendedSection(centered: centered)
                } else {
                    Spacer(minLength: centered ? 20 : 8)
                }

                footer(centered: centered)
            }
            .frame(width: panelWidth, height: panelHeight)
            .background {
                HDGlassSurface(
                    tint: p.startMenu,
                    enabled: transparency,
                    tintOpacity: scheme == .dark ? 0.72 : 0.80
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: centered ? 12 : metrics.startRadius))
            .overlay(
                RoundedRectangle(cornerRadius: centered ? 12 : metrics.startRadius)
                    .stroke(p.border.opacity(0.82), lineWidth: 1)
            )
            .shadow(color: .black.opacity(scheme == .dark ? 0.40 : 0.24), radius: 20, y: 8)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: centered ? .bottom : .bottomLeading
            )
            .padding(.leading, centered ? 0 : 8)
            .padding(.bottom, centered ? 12 : 8)
            .onAppear {
                if showSearch && startSearchFocus {
                    DispatchQueue.main.async {
                        searchFocused = true
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func searchHeader(centered: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(p.primary)

            TextField("Search for apps, settings, and documents", text: $search)
                .font(.system(size: centered ? 13 : 13.6))
                .foregroundColor(p.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($searchFocused)
        }
        .padding(.horizontal, 14)
        .frame(height: centered ? 34 : 36)
        .background(
            RoundedRectangle(cornerRadius: centered ? 8 : 18)
                .fill(
                    scheme == .dark
                        ? Color.white.opacity(0.085)
                        : Color.white.opacity(0.80)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: centered ? 8 : 18)
                .stroke(
                    scheme == .dark
                        ? Color.white.opacity(0.10)
                        : p.border.opacity(0.50),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, centered ? 30 : 20)
        .padding(.top, centered ? 24 : 16)
        .padding(.bottom, centered ? 18 : 12)
    }

    @ViewBuilder
    private func pinnedSection(centered: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Pinned")
                    .font(.system(size: centered ? 14 : metrics.startHeaderFontSize, weight: .semibold))
                    .foregroundColor(p.text)

                Spacer()

                Button {
                    search = ""
                } label: {
                    HStack(spacing: 5) {
                        Text("All")
                            .font(.system(size: 11.5, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(p.text)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.white.opacity(scheme == .dark ? 0.07 : 0.62))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(p.border.opacity(0.40), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, centered ? 46 : metrics.startTitlePaddingHorizontal)
            .padding(.bottom, centered ? 12 : 6)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(minimum: 64, maximum: 88), spacing: centered ? 8 : 0),
                        count: columnCount
                    ),
                    spacing: centered ? 8 : 0
                ) {
                    ForEach(filtered) { app in
                        Button {
                            onOpen(app)
                        } label: {
                            VStack(spacing: centered ? 7 : 4) {
                                HDImage(name: app.asset)
                                    .frame(
                                        width: centered ? 34 : metrics.startAppIconSize,
                                        height: centered ? 34 : metrics.startAppIconSize
                                    )

                                Text(app.title)
                                    .font(.system(size: centered ? 10.5 : 11))
                                    .foregroundColor(p.text)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                                    .frame(maxWidth: .infinity)
                            }
                            .frame(
                                maxWidth: .infinity,
                                minHeight: centered ? 72 : metrics.startAppHeight
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, centered ? 34 : metrics.startGridPaddingHorizontal)
            }
            .frame(
                height: centered
                    ? (compact ? 154 : 218)
                    : (compact ? max(150, metrics.startGridHeight - 70) : metrics.startGridHeight)
            )
        }
    }

    @ViewBuilder
    private func recommendedSection(centered: Bool) -> some View {
        VStack(alignment: .leading, spacing: centered ? 13 : 12) {
            Text("Recommended")
                .font(.system(size: centered ? 14 : metrics.startHeaderFontSize, weight: .semibold))
                .foregroundColor(p.text)

            Text("The more you use your device, the more we'll show you recent files and new apps here.")
                .font(.system(size: centered ? 11.5 : 12.2))
                .foregroundColor(p.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, centered ? 46 : (metrics.landscape ? 42 : 18))
        .padding(.top, centered ? 22 : 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func footer(centered: Bool) -> some View {
        HStack {
            Button(action: {}) {
                HStack(spacing: centered ? 10 : 12) {
                    HDImage(name: "img_user_default")
                        .frame(width: centered ? 28 : 24, height: centered ? 28 : 24)
                        .clipShape(Circle())

                    Text(accountName.isEmpty ? "Name" : accountName)
                        .font(.system(size: centered ? 11.5 : 12, weight: .medium))
                        .foregroundColor(p.text)
                }
                .padding(.horizontal, centered ? 12 : 10)
                .frame(height: centered ? 50 : 42)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: {}) {
                Image(systemName: "power")
                    .font(.system(size: centered ? 16 : 15, weight: .medium))
                    .foregroundColor(p.text)
                    .frame(width: centered ? 44 : 40, height: centered ? 44 : 42)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, centered ? 42 : metrics.startBodyPaddingHorizontal)
        .padding(.vertical, centered ? 6 : metrics.startFooterPadding)
        .background(
            p.footer.opacity(centered ? 0.92 : 1.0)
        )
        .overlay(
            Rectangle()
                .fill(p.border.opacity(0.18))
                .frame(height: 1),
            alignment: .top
        )
    }
}
