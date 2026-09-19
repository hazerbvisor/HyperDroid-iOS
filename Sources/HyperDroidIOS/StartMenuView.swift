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
        switch startColumns {
        case "4 columns": return 4
        case "6 columns": return 6
        default: return taskbarAlignment == "Center" ? 6 : 6
        }
    }

    private var recommendedApps: [HDAppEntry] {
        Array(HDAppEntry.builtIns.prefix(4))
    }

    var body: some View {
        GeometryReader { geo in
            if taskbarAlignment == "Center" {
                centeredStart(in: geo.size)
            } else {
                leftStart(in: geo.size)
            }
        }
    }

    @ViewBuilder
    private func centeredStart(in size: CGSize) -> some View {
        let panelWidth = min(642, size.width - 32)
        let maxPanelHeight = max(420, size.height - metrics.taskbarHeight - 24)
        let regularHeight = min(724, maxPanelHeight)
        let panelHeight = compact ? max(420, regularHeight - 120) : regularHeight

        VStack(spacing: 0) {
            if showSearch {
                searchHeader(centered: true)
            }

            pinnedSection(centered: true)

            if showRecommended && !compact {
                centeredRecommended
            } else {
                Spacer(minLength: 20)
            }

            footer(centered: true)
        }
        .frame(width: panelWidth, height: panelHeight)
        .background {
            HDGlassSurface(
                tint: p.startMenu,
                enabled: transparency,
                tintOpacity: scheme == .dark ? 0.72 : 0.80
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(p.border.opacity(0.82), lineWidth: 1)
        )
        .shadow(color: .black.opacity(scheme == .dark ? 0.40 : 0.24), radius: 20, y: 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 12)
        .onAppear(perform: focusSearchIfNeeded)
    }

    @ViewBuilder
    private func leftStart(in size: CGSize) -> some View {
        // Windows 11 left-aligned Start is a separate compact shell, not the
        // centered panel moved sideways.
        let panelWidth = min(458, size.width - 18)
        let maxPanelHeight = max(390, size.height - metrics.taskbarHeight - 12)
        let regularHeight = min(548, maxPanelHeight)
        let panelHeight = compact ? max(388, regularHeight - 92) : regularHeight

        VStack(spacing: 0) {
            if showSearch {
                searchHeader(centered: false)
            }

            leftPinnedSection

            if showRecommended && !compact && search.isEmpty {
                leftRecommended
            } else {
                Spacer(minLength: 10)
            }

            footer(centered: false)
        }
        .frame(width: panelWidth, height: panelHeight)
        .background {
            HDGlassSurface(
                tint: p.startMenu,
                enabled: transparency,
                tintOpacity: scheme == .dark ? 0.74 : 0.84
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(p.border.opacity(0.76), lineWidth: 1)
        )
        .shadow(color: .black.opacity(scheme == .dark ? 0.36 : 0.22), radius: 15, y: 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(.leading, 6)
        .padding(.bottom, 6)
        .onAppear(perform: focusSearchIfNeeded)
    }

    @ViewBuilder
    private func searchHeader(centered: Bool) -> some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: centered ? 13 : 11.5, weight: .semibold))
                .foregroundColor(p.primary)

            TextField(
                centered
                    ? "Search for apps, settings, and documents"
                    : "Type here to search",
                text: $search
            )
            .font(.system(size: centered ? 13 : 11.5))
            .foregroundColor(p.text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($searchFocused)
        }
        .padding(.horizontal, centered ? 14 : 10)
        .frame(height: centered ? 34 : 30)
        .background(
            RoundedRectangle(cornerRadius: centered ? 8 : 4)
                .fill(
                    scheme == .dark
                        ? Color.white.opacity(centered ? 0.085 : 0.075)
                        : Color.white.opacity(centered ? 0.80 : 0.90)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: centered ? 8 : 4)
                .stroke(
                    scheme == .dark
                        ? Color.white.opacity(0.10)
                        : p.border.opacity(0.55),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, centered ? 30 : 14)
        .padding(.top, centered ? 24 : 12)
        .padding(.bottom, centered ? 18 : 12)
    }

    @ViewBuilder
    private func pinnedSection(centered: Bool) -> some View {
        VStack(spacing: 0) {
            sectionHeader(
                title: "Pinned",
                allTitle: "All",
                centered: centered
            )

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(minimum: 64, maximum: 88), spacing: 8),
                        count: columnCount
                    ),
                    spacing: 8
                ) {
                    ForEach(filtered) { app in
                        appTile(app, centered: centered)
                    }
                }
                .padding(.horizontal, 34)
            }
            .frame(height: compact ? 154 : 218)
        }
    }

    private var leftPinnedSection: some View {
        VStack(spacing: 0) {
            sectionHeader(
                title: "Pinned",
                allTitle: "All apps",
                centered: false
            )

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(minimum: 48, maximum: 62), spacing: 5),
                        count: columnCount
                    ),
                    spacing: 4
                ) {
                    ForEach(filtered) { app in
                        appTile(app, centered: false)
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: compact ? 132 : 176)
        }
    }

    @ViewBuilder
    private func sectionHeader(
        title: String,
        allTitle: String,
        centered: Bool
    ) -> some View {
        HStack {
            Text(title)
                .font(.system(size: centered ? 14 : 11.5, weight: .semibold))
                .foregroundColor(p.text)

            Spacer()

            Button(action: {}) {
                HStack(spacing: 4) {
                    Text(allTitle)
                        .font(.system(size: centered ? 11.5 : 9.8, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: centered ? 9 : 7.5, weight: .semibold))
                }
                .foregroundColor(p.text)
                .padding(.horizontal, centered ? 10 : 7)
                .frame(height: centered ? 26 : 22)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(scheme == .dark ? 0.07 : 0.60))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(p.border.opacity(0.38), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, centered ? 46 : 24)
        .padding(.bottom, centered ? 12 : 8)
    }

    @ViewBuilder
    private func appTile(_ app: HDAppEntry, centered: Bool) -> some View {
        Button {
            onOpen(app)
        } label: {
            VStack(spacing: centered ? 7 : 5) {
                HDImage(name: app.asset)
                    .frame(
                        width: centered ? 34 : 28,
                        height: centered ? 34 : 28
                    )

                Text(app.title)
                    .font(.system(size: centered ? 10.5 : 8.8))
                    .foregroundColor(p.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(maxWidth: .infinity)
            }
            .frame(
                maxWidth: .infinity,
                minHeight: centered ? 72 : 55
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var centeredRecommended: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("Recommended")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(p.text)

            Text("The more you use your device, the more we'll show you recent files and new apps here.")
                .font(.system(size: 11.5))
                .foregroundColor(p.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 46)
        .padding(.top, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var leftRecommended: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommended")
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(p.text)
                .padding(.horizontal, 24)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 5
            ) {
                ForEach(recommendedApps) { app in
                    Button {
                        onOpen(app)
                    } label: {
                        HStack(spacing: 8) {
                            HDImage(name: app.asset)
                                .frame(width: 22, height: 22)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(app.title)
                                    .font(.system(size: 9.5, weight: .medium))
                                    .foregroundColor(p.text)
                                    .lineLimit(1)
                                Text("Recently added")
                                    .font(.system(size: 7.8))
                                    .foregroundColor(p.mutedText)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 8)
                        .frame(height: 38)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func footer(centered: Bool) -> some View {
        HStack {
            Button(action: {}) {
                HStack(spacing: centered ? 10 : 8) {
                    HDImage(name: "img_user_default")
                        .frame(
                            width: centered ? 28 : 24,
                            height: centered ? 28 : 24
                        )
                        .clipShape(Circle())

                    Text(accountName.isEmpty ? "Name" : accountName)
                        .font(.system(size: centered ? 11.5 : 9.8, weight: .medium))
                        .foregroundColor(p.text)
                }
                .padding(.horizontal, centered ? 12 : 8)
                .frame(height: centered ? 50 : 42)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: {}) {
                Image(systemName: "power")
                    .font(.system(size: centered ? 16 : 13.5, weight: .medium))
                    .foregroundColor(p.text)
                    .frame(
                        width: centered ? 44 : 38,
                        height: centered ? 44 : 38
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, centered ? 42 : 24)
        .padding(.vertical, centered ? 6 : 4)
        .background(p.footer.opacity(centered ? 0.92 : 0.96))
        .overlay(
            Rectangle()
                .fill(p.border.opacity(0.18))
                .frame(height: 1),
            alignment: .top
        )
    }

    private func focusSearchIfNeeded() {
        if showSearch && startSearchFocus {
            DispatchQueue.main.async {
                searchFocused = true
            }
        }
    }
}
