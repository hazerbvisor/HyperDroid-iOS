import SwiftUI

struct HDSearchPanelView: View {
    let onOpen: (HDAppEntry) -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var query = ""
    @FocusState private var searchFocused: Bool
    @AppStorage("hd.transparency") private var transparency = true

    private var p: HDPalette { HDPalette(scheme: scheme) }

    private var filteredApps: [HDAppEntry] {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Array(HDAppEntry.builtIns.prefix(6))
        }
        return HDAppEntry.builtIns.filter {
            $0.title.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(p.mutedText)

                TextField("Type here to search", text: $query)
                    .font(.system(size: 13))
                    .foregroundColor(p.text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($searchFocused)
                    .hdCursor(.ibeam)
            }
            .padding(.horizontal, 13)
            .frame(height: 38)
            .background(Color.white.opacity(scheme == .dark ? 0.10 : 0.58))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(p.border.opacity(0.45), lineWidth: 1)
            )
            .padding(12)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(query.isEmpty ? "Quick searches" : "Apps")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(p.text)

                    if query.isEmpty {
                        HStack(spacing: 10) {
                            quickTile("Tips", icon: "lightbulb")
                            quickTile("Translate", icon: "character.book.closed")
                            quickTile("Today in history", icon: "clock.arrow.circlepath")
                        }
                    }

                    if !filteredApps.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(query.isEmpty ? "Apps" : "Best match")
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundColor(p.mutedText)

                            ForEach(filteredApps) { app in
                                Button {
                                    onOpen(app)
                                } label: {
                                    HStack(spacing: 12) {
                                        HDImage(name: app.asset)
                                            .frame(width: 26, height: 26)

                                        Text(app.title)
                                            .font(.system(size: 12.5))
                                            .foregroundColor(p.text)

                                        Spacer()
                                    }
                                    .padding(.horizontal, 10)
                                    .frame(height: 46)
                                    .background(Color.white.opacity(0.001))
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .hdCursor(.hand)
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 24))
                            Text("No results for “\(query)”")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(p.mutedText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }

            HStack {
                HDImage(name: "img_user_default")
                    .frame(width: 22, height: 22)
                    .clipShape(Circle())
                Text("Search")
                    .font(.system(size: 11.5))
                    .foregroundColor(p.mutedText)
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(p.footer)
        }
        .frame(width: 350, height: 480)
        .background {
            HDGlassSurface(
                tint: p.startMenu,
                enabled: transparency,
                tintOpacity: scheme == .dark ? 0.62 : 0.78
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(p.border.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 14, y: 6)
        .onAppear {
            DispatchQueue.main.async {
                searchFocused = true
            }
        }
    }

    private func quickTile(_ title: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(p.primary)
            Text(title)
                .font(.system(size: 10.5))
                .foregroundColor(p.text)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(p.dialogBody.opacity(0.70))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}
