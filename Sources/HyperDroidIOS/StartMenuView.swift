import SwiftUI

struct HDStartMenuView: View {
    let metrics: HDMetrics
    let onOpen: (HDAppEntry) -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var search = ""
    private var p: HDPalette { HDPalette(scheme: scheme) }

    var filtered: [HDAppEntry] {
        search.isEmpty ? HDAppEntry.builtIns : HDAppEntry.builtIns.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        GeometryReader { geo in
            let height = min(metrics.startMaxHeight, max(metrics.startMinHeight, geo.size.height * 0.78))
            VStack(spacing: 0) {
                header
                bodyContent
                footer
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(p.startMenu)
            .clipShape(RoundedRectangle(cornerRadius: metrics.startRadius))
            .overlay(RoundedRectangle(cornerRadius: metrics.startRadius).stroke(p.border, lineWidth: 1))
            .shadow(color: .black.opacity(0.28), radius: 12, y: 5)
            .padding(.horizontal, 8)
            .padding(.top, 14)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            HDImage(name: "ic_search_18_sparkle", template: true, tint: p.text).frame(width: 18, height: 18)
            TextField("Type here to search", text: $search)
                .font(.system(size: 13.6))
                .foregroundColor(p.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.white.opacity(scheme == .dark ? 0.10 : 0.38))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(p.border.opacity(0.45), lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(p.footer)
    }

    private var bodyContent: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Apps")
                    .font(.system(size: metrics.startHeaderFontSize, weight: .bold))
                    .foregroundColor(p.text)
                Spacer()
                Button(action: {}) {
                    HDImage(name: "menu_ic_reorder_12_regular", template: true, tint: p.text).frame(width: 12, height: 12)
                        .padding(.horizontal, 18)
                        .frame(height: 28)
                }.buttonStyle(.plain)
                Button(action: {}) {
                    HStack(spacing: 10) {
                        Text(". .").font(.system(size: 11.6))
                        HDImage(name: "ic_arrow_down_12_regular", template: true, tint: p.text).frame(width: 12, height: 12)
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 28)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(p.border.opacity(0.45), lineWidth: 1))
                }.buttonStyle(.plain)
            }
            .padding(.leading, metrics.startTitlePaddingHorizontal)
            .padding(.trailing, metrics.startTitlePaddingHorizontal)
            .padding(.top, 18)
            .padding(.vertical, 4)

            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(metrics.startAppWidth), spacing: 0), count: metrics.landscape ? 6 : 4), spacing: 0) {
                    ForEach(filtered) { app in
                        Button { onOpen(app) } label: {
                            VStack(spacing: 0) {
                                HDImage(name: app.asset)
                                    .frame(width: metrics.startAppIconSize, height: metrics.startAppIconSize)
                                Text(app.title)
                                    .font(.system(size: 11))
                                    .foregroundColor(p.text)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 4.4)
                                    .padding(.top, 4)
                            }
                            .frame(width: metrics.startAppWidth, height: metrics.startAppHeight)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: metrics.startGridHeight)
            .padding(.horizontal, metrics.startGridPaddingHorizontal)
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 12) {
                Text("Recommended")
                    .font(.system(size: metrics.startHeaderFontSize, weight: .bold))
                Text("The more you use your device, we will show you new apps here.")
                    .font(.system(size: 12.2))
                    .foregroundColor(p.mutedText)
            }
            .foregroundColor(p.text)
            .padding(.horizontal, metrics.landscape ? 42 : 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var footer: some View {
        HStack {
            Button(action: {}) {
                HStack(spacing: 12) {
                    HDImage(name: "img_user_default").frame(width: 24, height: 24).clipShape(Circle())
                    Text("Name").font(.system(size: 12)).foregroundColor(p.text)
                }
                .padding(.horizontal, 10)
                .frame(height: 42)
            }.buttonStyle(.plain)
            Spacer()
            Button(action: {}) {
                HDImage(name: "ic_power_20_regular", template: true, tint: p.text)
                    .frame(width: 19, height: 19)
                    .padding(10)
                    .frame(height: 42)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, metrics.startBodyPaddingHorizontal)
        .padding(.vertical, metrics.startFooterPadding)
        .background(p.footer)
        .overlay(Rectangle().fill(p.border.opacity(0.18)).frame(height: 1), alignment: .top)
    }
}
